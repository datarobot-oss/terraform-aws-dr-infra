data "aws_availability_zones" "available" {}

data "aws_caller_identity" "current" {}


################################################################################
# VPC
################################################################################

locals {
  azs    = slice(data.aws_availability_zones.available.names, 0, 3)
  vpc_id = var.create_vpc && var.vpc_id == "" ? module.vpc[0].vpc_id : var.vpc_id
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

module "endpoints" {
  source  = "terraform-aws-modules/vpc/aws//modules/vpc-endpoints"
  version = "~> 5.0"
  count   = var.create_vpc && var.vpc_id == "" && length(var.vpc_endpoints) > 0 ? 1 : 0

  vpc_id                     = module.vpc[0].vpc_id
  create_security_group      = true
  security_group_name        = "${var.name}-endpoints"
  security_group_description = "VPC endpoint default security group"
  security_group_rules = {
    ingress_https = {
      description = "HTTPS from VPC"
      cidr_blocks = [module.vpc[0].vpc_cidr_block]
    }
  }

  endpoints = { for endpoint_service in var.vpc_endpoints :
    endpoint_service => {
      service             = endpoint_service
      subnet_ids          = module.vpc[0].private_subnets
      private_dns_enabled = true
      dns_options = {
        private_dns_only_for_inbound_resolver_endpoint = false
      }
    }
  }

  tags = var.tags
}


################################################################################
# DNS
################################################################################

locals {
  # keys used by the "dns" module. these are not the actual domain names associated with the zones.
  public_route53_zone_key  = var.domain_name
  private_route53_zone_key = "private.${var.domain_name}"
}

module "dns" {
  source  = "terraform-aws-modules/route53/aws//modules/zones"
  version = "~> 3.0"
  count   = var.create_dns_zone && var.route53_zone_id == "" ? 1 : 0

  zones = {
    (local.public_route53_zone_key) = {
      domain_name   = var.domain_name
      comment       = "${var.domain_name} public zone"
      force_destroy = var.dns_zone_force_destroy
    },
    (local.private_route53_zone_key) = {
      domain_name   = var.domain_name
      vpc           = [{ vpc_id = local.vpc_id }]
      comment       = "${var.domain_name} private zone"
      force_destroy = var.dns_zone_force_destroy
    }
  }

  tags = var.tags
}


################################################################################
# ACM
################################################################################

locals {
  cert_validation_route53_zone_id = var.create_dns_zone && var.route53_zone_id == "" ? module.dns[0].route53_zone_zone_id[local.public_route53_zone_key] : var.route53_zone_id
}

module "acm" {
  source  = "terraform-aws-modules/acm/aws"
  version = "~> 4.0"
  count   = var.create_acm_certificate && var.acm_certificate_arn == "" ? 1 : 0

  domain_name = var.domain_name
  zone_id     = local.cert_validation_route53_zone_id

  subject_alternative_names = [
    var.domain_name,
    "*.${var.domain_name}"
  ]

  wait_for_validation = true
  validation_method   = "DNS"
  validation_timeout  = "10m"

  tags = var.tags
}


################################################################################
# KMS
################################################################################

locals {
  kms_key_arn = var.create_kms_key && var.kms_key_arn == "" ? module.kms[0].key_arn : var.kms_key_arn
}

module "kms" {
  source  = "terraform-aws-modules/kms/aws"
  version = "~> 3.0"
  count   = var.create_kms_key && var.kms_key_arn == "" ? 1 : 0

  description = "Ec2 AutoScaling key usage"
  key_usage   = "ENCRYPT_DECRYPT"

  key_administrators                = [data.aws_caller_identity.current.arn]
  key_service_roles_for_autoscaling = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/aws-service-role/autoscaling.amazonaws.com/AWSServiceRoleForAutoScaling"]

  aliases = ["datarobot/ebs"]

  tags = var.tags
}


################################################################################
# S3
################################################################################

locals {
  s3_bucket_id = var.create_s3_bucket && var.s3_bucket_id == "" ? module.storage[0].s3_bucket_id : var.s3_bucket_id
}

module "storage" {
  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "~> 4.0"
  count   = var.create_s3_bucket && var.s3_bucket_id == "" ? 1 : 0

  bucket_prefix = replace(var.name, "_", "-")
  force_destroy = var.s3_bucket_force_destroy

  tags = var.tags
}


################################################################################
# ECR
################################################################################

module "ecr" {
  source   = "terraform-aws-modules/ecr/aws"
  version  = "~> 2.0"
  for_each = var.create_ecr_repositories ? var.ecr_repositories : []

  repository_name               = "${var.name}/${each.key}"
  repository_image_scan_on_push = false
  repository_force_delete       = var.ecr_repositories_force_destroy
  attach_repository_policy      = false
  create_lifecycle_policy       = false

  tags = var.tags
}


################################################################################
# EKS
################################################################################

locals {
  eks_subnet_ids = var.create_vpc && length(var.eks_subnet_ids) == 0 ? module.vpc[0].private_subnets : var.eks_subnet_ids
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.0"
  count   = var.create_eks_cluster ? 1 : 0

  cluster_name    = var.name
  cluster_version = var.eks_cluster_version

  cluster_endpoint_public_access       = var.eks_cluster_endpoint_public_access
  cluster_endpoint_public_access_cidrs = var.eks_cluster_endpoint_public_access_cidrs

  cluster_addons = {
    coredns                = {}
    eks-pod-identity-agent = {}
    kube-proxy             = {}
    vpc-cni                = {}
  }

  enable_cluster_creator_admin_permissions = true
  access_entries                           = var.eks_cluster_access_entries

  vpc_id     = local.vpc_id
  subnet_ids = local.eks_subnet_ids

  cluster_security_group_additional_rules = length(var.eks_cluster_endpoint_private_access_cidrs) != 0 ? {
    ingress_custom_https = {
      description = "Custom hosts to control plane"
      protocol    = "tcp"
      from_port   = 443
      to_port     = 443
      type        = "ingress"
      cidr_blocks = var.eks_cluster_endpoint_private_access_cidrs
    }
  } : {}

  eks_managed_node_group_defaults = {
    block_device_mappings = {
      xvda = {
        device_name = "/dev/xvda"
        ebs = {
          delete_on_termination = true
          encrypted             = var.create_kms_key || var.kms_key_arn != ""
          iops                  = 2000
          kms_key_id            = local.kms_key_arn
          volume_size           = 200
          volume_type           = "gp3"
        }
      }
    }
  }

  eks_managed_node_groups = merge(
    {
      primary = {
        ami_type       = var.eks_primary_nodegroup_ami_type
        instance_types = var.eks_primary_nodegroup_instance_types
        min_size       = var.eks_primary_nodegroup_min_size
        max_size       = var.eks_primary_nodegroup_max_size
        desired_size   = var.eks_primary_nodegroup_desired_size
        taints         = var.eks_primary_nodegroup_taints
      }
    },
    var.create_eks_gpu_nodegroup ? {
      gpu = {
        ami_type       = var.eks_gpu_nodegroup_ami_type
        instance_types = var.eks_gpu_nodegroup_instance_types
        min_size       = var.eks_gpu_nodegroup_min_size
        max_size       = var.eks_gpu_nodegroup_max_size
        desired_size   = var.eks_gpu_nodegroup_desired_size
        taints         = var.eks_gpu_nodegroup_taints
      }
    } : {}
  )

  tags = var.tags
}


################################################################################
# APP IRSA
################################################################################

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
