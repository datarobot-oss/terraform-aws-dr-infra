data "aws_availability_zones" "available" {}

data "aws_eks_cluster_auth" "this" {
  name = module.eks[0].cluster_name
}

data "aws_route53_zone" "this" {
  count   = var.route53_zone_id != "" ? 1 : 0
  zone_id = var.route53_zone_id
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

  vpc_id           = var.create_vpc && var.vpc_id == "" ? module.vpc[0].vpc_id : var.vpc_id
  eks_subnet_ids   = var.create_vpc && length(var.eks_subnet_ids) == 0 ? module.vpc[0].private_subnets : var.eks_subnet_ids
  eks_cluster_name = var.create_eks_cluster && var.eks_cluster_name == "" ? module.eks[0].cluster_name : var.eks_cluster_name

  # keys used by the "dns" module. these are not the actual domain names associated with the zones.
  public_route53_zone_key  = var.app_fqdn
  private_route53_zone_key = "private.${var.app_fqdn}"

  cert_validation_route53_zone_id  = var.create_dns_zone && var.route53_zone_id == "" ? module.dns[0].route53_zone_zone_id[local.public_route53_zone_key] : var.route53_zone_id
  cert_validation_route53_zone_arn = try(data.aws_route53_zone.this[0].arn, module.dns[0].route53_zone_zone_arn[local.public_route53_zone_key])

  external_dns_route53_zone_arn  = try(data.aws_route53_zone.this[0].arn, module.dns[0].route53_zone_zone_arn[var.internet_facing_ingress_lb ? local.public_route53_zone_key : local.private_route53_zone_key])
  external_dns_route53_zone_name = try(data.aws_route53_zone.this[0].name, var.app_fqdn)

  s3_bucket_id = var.create_s3_storage_bucket && var.s3_bucket_id == "" ? module.storage[0].s3_bucket_id : var.s3_bucket_id

  acm_certificate_arn = var.create_acm_certificate && var.acm_certificate_arn == "" ? module.acm[0].acm_certificate_arn : var.acm_certificate_arn
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"
  count   = var.create_vpc && var.vpc_id == "" ? 1 : 0

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
  count   = var.create_dns_zone ? 1 : 0

  zones = {
    "${local.public_route53_zone_key}" = {
      domain_name   = var.app_fqdn
      comment       = "${var.app_fqdn} public zone"
      force_destroy = true
    },
    "${local.private_route53_zone_key}" = {
      domain_name   = var.app_fqdn
      vpc           = [{ vpc_id = local.vpc_id }]
      comment       = "${var.app_fqdn} private zone"
      force_destroy = true
    }
  }

  tags = var.tags
}

module "acm" {
  source  = "terraform-aws-modules/acm/aws"
  version = "~> 4.0"
  count   = var.create_acm_certificate ? 1 : 0

  domain_name = var.app_fqdn
  zone_id     = local.cert_validation_route53_zone_id

  subject_alternative_names = [
    var.app_fqdn
  ]

  wait_for_validation = true
  validation_method   = "DNS"
  validation_timeout  = "10m"

  tags = var.tags
}

module "storage" {
  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "~> 4.0"
  count   = var.create_s3_storage_bucket ? 1 : 0

  bucket_prefix = replace(var.name, "_", "-")
  force_destroy = true

  tags = var.tags
}

module "ecr" {
  source   = "terraform-aws-modules/ecr/aws"
  version  = "~> 2.0"
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
  cluster_version = var.eks_cluster_version

  cluster_endpoint_public_access = true

  cluster_addons = {
    coredns                = {}
    eks-pod-identity-agent = {}
    kube-proxy             = {}
    vpc-cni                = {}
  }

  enable_cluster_creator_admin_permissions = true

  vpc_id     = local.vpc_id
  subnet_ids = local.eks_subnet_ids

  eks_managed_node_groups = {
    primary = {
      instance_types = ["r6i.4xlarge"]

      min_size     = 5
      max_size     = 10
      desired_size = 6

      disk_size                  = 200
      use_custom_launch_template = false
    }
  }

  tags = var.tags
}

module "app_irsa_role" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-assumable-role-with-oidc"
  version = "~> 5.0"
  count   = var.create_app_irsa_role ? 1 : 0

  create_role = true
  role_name   = "${var.name}-app-irsa"

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
        "arn:aws:s3:::${local.s3_bucket_id}/*",
        "arn:aws:s3:::${local.s3_bucket_id}"
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

module "aws_load_balancer_controller" {
  source = "./modules/aws-load-balancer-controller"
  count  = var.aws_load_balancer_controller ? 1 : 0

  eks_cluster_name = local.eks_cluster_name
  vpc_id           = local.vpc_id

  custom_values_templatefile = var.aws_load_balancer_controller_values
  custom_values_variables    = var.aws_load_balancer_controller_variables

  tags = var.tags
}

module "cert_manager" {
  source = "./modules/cert-manager"
  count  = var.cert_manager ? 1 : 0

  eks_cluster_name = local.eks_cluster_name
  route53_zone_arn = local.cert_validation_route53_zone_arn

  custom_values_templatefile = var.cert_manager_values
  custom_values_variables    = var.cert_manager_variables

  tags = var.tags
}

module "cluster_autoscaler" {
  source = "./modules/cluster-autoscaler"
  count  = var.cluster_autoscaler ? 1 : 0

  eks_cluster_name = local.eks_cluster_name

  custom_values_templatefile = var.cluster_autoscaler_values
  custom_values_variables    = var.cluster_autoscaler_variables

  tags = var.tags
}

module "ebs_csi_driver" {
  source = "./modules/ebs-csi-driver"
  count  = var.ebs_csi_driver ? 1 : 0

  eks_cluster_name     = local.eks_cluster_name
  aws_ebs_csi_kms_arns = []

  custom_values_templatefile = var.ebs_csi_driver_values
  custom_values_variables    = var.ebs_csi_driver_variables

  tags = var.tags
}

module "external_dns" {
  source = "./modules/external-dns"
  count  = var.external_dns ? 1 : 0

  eks_cluster_name  = local.eks_cluster_name
  route53_zone_arn  = local.external_dns_route53_zone_arn
  route53_zone_name = local.external_dns_route53_zone_name

  custom_values_templatefile = var.external_dns_values
  custom_values_variables    = var.external_dns_variables

  tags = var.tags
}

module "ingress_nginx" {
  source = "./modules/ingress-nginx"
  count  = var.ingress_nginx ? 1 : 0

  acm_certificate_arn = local.acm_certificate_arn
  app_fqdn            = var.app_fqdn
  public              = var.internet_facing_ingress_lb

  custom_values_templatefile = var.ingress_nginx_values
  custom_values_variables    = var.ingress_nginx_variables

  tags = var.tags
}
