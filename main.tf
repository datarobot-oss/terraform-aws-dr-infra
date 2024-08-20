data "aws_availability_zones" "available" {}

data "aws_eks_cluster_auth" "this" {
  name = module.eks[0].cluster_name
}

provider "helm" {
  kubernetes {
    host                   = module.eks[0].cluster_endpoint
    cluster_ca_certificate = base64decode(module.eks[0].cluster_certificate_authority_data)
    token                  = data.aws_eks_cluster_auth.this.token
  }
}

locals {
  azs = slice(data.aws_availability_zones.available.names, 0, 3)

  ecr_repos = var.create_ecr_repositories ? toset([
    "base-image",
    "ephemeral-image",
    "managed-image",
    "custom-apps-managed-image"
  ]) : []

  zone_name = "${var.name}.${var.dns_zone}"
  app_fqdn  = "app.${local.zone_name}"
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"
  count   = var.create_vpc ? 1 : 0

  name = var.name
  cidr = var.vpc_cidr

  azs             = local.azs
  private_subnets = [for k, v in local.azs : cidrsubnet(var.vpc_cidr, 4, k)]
  public_subnets  = [for k, v in local.azs : cidrsubnet(var.vpc_cidr, 8, k + 48)]

  enable_nat_gateway = true
  single_nat_gateway = true

  public_subnet_tags = {
    "kubernetes.io/role/elb" = 1
  }
  private_subnet_tags = {
    "kubernetes.io/role/internal-elb" = 1
  }

  tags = var.tags
}

module "dns" {
  source  = "terraform-aws-modules/route53/aws//modules/zones"
  version = "~> 3.0"
  count   = var.create_dns ? 1 : 0

  zones = {
    "${local.zone_name}" = {
      force_destroy = true
    }
  }

  tags = var.tags
}

module "acm" {
  source  = "terraform-aws-modules/acm/aws"
  version = "~> 4.0"
  count   = var.create_acm_certificate ? 1 : 0

  domain_name = local.zone_name
  zone_id     = module.dns[0].route53_zone_zone_id[local.zone_name]

  validation_method = "DNS"

  subject_alternative_names = [
    local.app_fqdn
  ]

  wait_for_validation = true

  tags = var.tags
}

module "storage" {
  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "~> 4.0"
  count   = var.create_s3_storage_bucket ? 1 : 0

  bucket_prefix = replace(var.name, "_", "-")
  force_destroy = true
  #   acl           = "private"

  tags = var.tags
}

module "ecr" {
  source  = "terraform-aws-modules/ecr/aws"
  version = "~> 2.0"
  for_each = local.ecr_repos

  repository_name               = "${var.name}/${each.key}"
  repository_image_scan_on_push = false
  repository_force_delete       = true
  attach_repository_policy      = false
  create_lifecycle_policy       = false

  tags = var.tags
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.0"
  count   = var.create_eks_cluster ? 1 : 0

  cluster_name    = var.name
  cluster_version = "1.30"

  cluster_endpoint_public_access = true

  cluster_addons = {
    coredns                = {}
    eks-pod-identity-agent = {}
    kube-proxy             = {}
    vpc-cni                = {}
  }

  enable_cluster_creator_admin_permissions = true

  vpc_id     = module.vpc[0].vpc_id
  subnet_ids = module.vpc[0].private_subnets

  eks_managed_node_groups = {
    primary = {
      instance_types = ["r6i.4xlarge"]

      min_size     = 3
      max_size     = 10
      desired_size = 6

      disk_size                  = 500
      use_custom_launch_template = false
    }
  }

  tags = var.tags
}

# TODO: can we use terraform-aws-modules/eks-pod-identity/aws instead?
module "app_irsa_role" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-assumable-role-with-oidc"
  version = "~> 5.0"
  count   = var.create_app_irsa_role ? 1 : 0

  create_role = true
  role_name   = "${var.name}-irsa"

  provider_url                 = replace(module.eks[0].cluster_oidc_issuer_url, "https://", "")
  oidc_subjects_with_wildcards = ["system:serviceaccount:${var.kubernetes_namespace}:*"]

  role_policy_arns = [
    "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryPowerUser"
  ]
  inline_policy_statements = [
    {
      sid = "AllowAccessToS3Bucket"
      actions = [
        "s3:DeleteObject",
        "s3:Get*",
        "s3:PutObject",
        "s3:ReplicateDelete",
        "s3:ListMultipartUploadParts"
      ]
      resources = [
        "arn:aws:s3:::${module.storage[0].s3_bucket_id}/*",
        "arn:aws:s3:::${module.storage[0].s3_bucket_id}"
      ]
    },
    {
      sid = "AllowListBuckets"
      actions = [
        "s3:ListBucket",
        "s3:ListBucketVersions",
        "s3:ListAllMyBuckets"
      ]
      resources = ["arn:aws:s3:::*"]
    }
  ]

  tags = var.tags
}


module "amenities" {
  source = "./amenities"

  eks_cluster_name    = module.eks[0].cluster_name
  route53_zone_arn    = module.dns[0].route53_zone_zone_arn[local.zone_name]
  route53_zone_name   = local.zone_name
  acm_certificate_arn = module.acm[0].acm_certificate_arn
  app_fqdn            = local.app_fqdn
  vpc_id              = module.vpc[0].vpc_id

  aws_loadbalancer_controller           = var.aws_loadbalancer_controller
  aws_loadbalancer_controller_values    = var.aws_loadbalancer_controller_values
  aws_loadbalancer_controller_variables = var.aws_loadbalancer_controller_variables
  cert_manager                          = var.cert_manager
  cert_manager_values                   = var.cert_manager_values
  cert_manager_variables                = var.cert_manager_variables
  cluster_autoscaler                    = var.cluster_autoscaler
  cluster_autoscaler_values             = var.cluster_autoscaler_values
  cluster_autoscaler_variables          = var.cluster_autoscaler_variables
  ebs_csi_driver                        = var.ebs_csi_driver
  ebs_csi_driver_values                 = var.ebs_csi_driver_values
  ebs_csi_driver_variables              = var.ebs_csi_driver_variables
  external_dns                          = var.external_dns
  external_dns_values                   = var.external_dns_values
  external_dns_variables                = var.external_dns_variables
  ingress_nginx                         = var.ingress_nginx
  ingress_nginx_values                  = var.ingress_nginx_values
  ingress_nginx_variables               = var.ingress_nginx_variables

  tags = var.tags
}
