data "aws_availability_zones" "available" {}

data "aws_caller_identity" "current" {}

data "aws_route53_zone" "provided" {
  count   = var.route53_zone_id != "" ? 1 : 0
  zone_id = var.route53_zone_id
}


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
  acm_certificate_arn = var.create_acm_certificate && var.acm_certificate_arn == "" ? module.acm[0].acm_certificate_arn : var.acm_certificate_arn

  # use the provided zone or the created public zone to validate a created ACM certificate
  cert_validation_route53_zone_id  = var.create_dns_zone && var.route53_zone_id == "" ? module.dns[0].route53_zone_zone_id[local.public_route53_zone_key] : var.route53_zone_id
  cert_validation_route53_zone_arn = try(data.aws_route53_zone.provided[0].arn, module.dns[0].route53_zone_zone_arn[local.public_route53_zone_key], "")
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
      (var.eks_primary_nodegroup_name) = {
        ami_type       = var.eks_primary_nodegroup_ami_type
        instance_types = var.eks_primary_nodegroup_instance_types
        min_size       = var.eks_primary_nodegroup_min_size
        max_size       = var.eks_primary_nodegroup_max_size
        desired_size   = var.eks_primary_nodegroup_desired_size
        labels         = var.eks_primary_nodegroup_labels
        taints         = var.eks_primary_nodegroup_taints
      }
    },
    var.create_eks_gpu_nodegroup ? {
      (var.eks_gpu_nodegroup_name) = {
        ami_type       = var.eks_gpu_nodegroup_ami_type
        instance_types = var.eks_gpu_nodegroup_instance_types
        min_size       = var.eks_gpu_nodegroup_min_size
        max_size       = var.eks_gpu_nodegroup_max_size
        desired_size   = var.eks_gpu_nodegroup_desired_size
        labels         = var.eks_gpu_nodegroup_labels
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


################################################################################
# HELM CHARTS
################################################################################

data "aws_eks_cluster_auth" "this" {
  count = var.create_eks_cluster ? 1 : 0

  name = module.eks[0].cluster_name
}

provider "helm" {
  kubernetes {
    host                   = try(module.eks[0].cluster_endpoint, "")
    cluster_ca_certificate = base64decode(try(module.eks[0].cluster_certificate_authority_data, ""))
    token                  = try(data.aws_eks_cluster_auth.this[0].token, "")
  }
}


module "cluster_autoscaler" {
  source = "./modules/cluster-autoscaler"
  count  = var.create_eks_cluster && var.cluster_autoscaler ? 1 : 0

  eks_cluster_name = module.eks[0].cluster_name

  custom_values_templatefile = var.cluster_autoscaler_values
  custom_values_variables    = var.cluster_autoscaler_variables

  tags = var.tags
}


module "ebs_csi_driver" {
  source = "./modules/ebs-csi-driver"
  count  = var.create_eks_cluster && var.ebs_csi_driver ? 1 : 0

  eks_cluster_name    = module.eks[0].cluster_name
  aws_ebs_csi_kms_arn = local.kms_key_arn

  custom_values_templatefile = var.ebs_csi_driver_values
  custom_values_variables    = var.ebs_csi_driver_variables

  tags = var.tags
}


module "aws_load_balancer_controller" {
  source = "./modules/aws-load-balancer-controller"
  count  = var.create_eks_cluster && var.aws_load_balancer_controller ? 1 : 0

  eks_cluster_name = module.eks[0].cluster_name
  vpc_id           = local.vpc_id

  custom_values_templatefile = var.aws_load_balancer_controller_values
  custom_values_variables    = var.aws_load_balancer_controller_variables

  tags = var.tags
}


module "ingress_nginx" {
  source     = "./modules/ingress-nginx"
  count      = var.create_eks_cluster && var.ingress_nginx ? 1 : 0
  depends_on = [module.aws_load_balancer_controller]

  acm_certificate_arn = local.acm_certificate_arn
  public              = var.internet_facing_ingress_lb

  custom_values_templatefile = var.ingress_nginx_values
  custom_values_variables    = var.ingress_nginx_variables

  tags = var.tags
}


module "cert_manager" {
  source     = "./modules/cert-manager"
  count      = var.create_eks_cluster && var.cert_manager ? 1 : 0
  depends_on = [module.ingress_nginx]

  eks_cluster_name = module.eks[0].cluster_name
  route53_zone_arn = local.cert_validation_route53_zone_arn

  custom_values_templatefile = var.cert_manager_values
  custom_values_variables    = var.cert_manager_variables

  tags = var.tags
}


locals {
  external_dns_route53_zone_arn  = try(data.aws_route53_zone.provided[0].arn, module.dns[0].route53_zone_zone_arn[var.internet_facing_ingress_lb ? local.public_route53_zone_key : local.private_route53_zone_key], "")
  external_dns_route53_zone_name = try(data.aws_route53_zone.provided[0].name, var.domain_name)
}

module "external_dns" {
  source     = "./modules/external-dns"
  count      = var.create_eks_cluster && var.external_dns ? 1 : 0
  depends_on = [module.ingress_nginx]

  eks_cluster_name  = module.eks[0].cluster_name
  route53_zone_arn  = local.external_dns_route53_zone_arn
  route53_zone_name = local.external_dns_route53_zone_name

  custom_values_templatefile = var.external_dns_values
  custom_values_variables    = var.external_dns_variables

  tags = var.tags
}
