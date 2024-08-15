data "aws_availability_zones" "available" {}

data "aws_eks_cluster_auth" "this" {
  name = module.eks.cluster_name
}

provider "aws" {}

provider "helm" {
  kubernetes {
    host                   = module.eks.cluster_endpoint
    cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
    token                  = data.aws_eks_cluster_auth.this.token
  }
}

locals {
  azs = slice(data.aws_availability_zones.available.names, 0, 3)

  ecr_repos = toset([
    "base-image",
    "ephemeral-image",
    "managed-image",
    "custom-apps-managed-image"
  ])

  zone_name = "${var.name}.${var.dns_zone}"
  app_fqdn  = "app.${local.zone_name}"
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

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

  zones = {
    "${local.zone_name}" = {}
  }

  tags = var.tags
}

module "acm" {
  source  = "terraform-aws-modules/acm/aws"
  version = "~> 4.0"

  domain_name = local.zone_name
  zone_id     = module.dns.route53_zone_zone_id[local.zone_name]

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

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  eks_managed_node_groups = {
    primary = {
      instance_types = ["r6i.4xlarge"]

      min_size     = 3
      max_size     = 6
      desired_size = 3

      block_device_mappings = {
        device_name = "/dev/xvda"

        ebs = {
          volume_size           = 500
          volume_type           = "io1"
          root_iops             = 2000
          kms_key_id            = ""
          encrypted             = false
          delete_on_termination = true
        }
      }
    }
  }

  tags = var.tags
}

# TODO: can we use terraform-aws-modules/eks-pod-identity/aws instead?
module "app_irsa_role" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-assumable-role-with-oidc"
  version = "~> 5.0"

  create_role = true
  role_name   = "${var.name}-irsa"

  provider_url                 = replace(module.eks.cluster_oidc_issuer_url, "https://", "")
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
        "arn:aws:s3:::${module.storage.s3_bucket_id}/*",
        "arn:aws:s3:::${module.storage.s3_bucket_id}"
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


  eks_cluster_name  = module.eks.cluster_name
  route53_zone_arn  = module.dns.route53_zone_zone_arn[local.zone_name]
  route53_zone_name = local.zone_name

  cert_manager        = true
  cluster_autoscaler  = true
  ebs_csi_driver      = true
  external_dns        = true
  ingress_nginx       = true
  acm_certificate_arn = module.acm.acm_certificate_arn
  app_fqdn            = local.app_fqdn

  tags = var.tags
}
