data "aws_partition" "current" {}
data "aws_caller_identity" "current" {}
data "aws_availability_zones" "available" {
  state = "available"
  filter {
    name   = "opt-in-status"
    values = ["opt-in-not-required"]
  }
}


################################################################################
# Network
################################################################################

data "aws_vpc" "existing" {
  count = var.existing_vpc_id != null ? 1 : 0
  id    = var.existing_vpc_id
}

locals {
  azs      = slice(data.aws_availability_zones.available.names, 0, var.availability_zones)
  multi_az = var.availability_zones > 1
  vpc_id   = var.existing_vpc_id != null ? var.existing_vpc_id : try(module.network[0].vpc_id, null)
  vpc_cidr = try(data.aws_vpc.existing[0].cidr_block, var.network_address_space)
}

module "network" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 6.0"
  count   = var.create_network && var.existing_vpc_id == null ? 1 : 0

  name = var.name
  cidr = var.network_address_space

  azs              = local.azs
  public_subnets   = [for k, v in local.azs : cidrsubnet(var.network_address_space, 8, k)]
  private_subnets  = [for k, v in local.azs : cidrsubnet(var.network_address_space, 8, k + 3)]
  database_subnets = [for k, v in local.azs : cidrsubnet(var.network_address_space, 8, k + 6)]

  create_database_subnet_group = false

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
  version = "~> 6.0"
  count   = var.create_network && var.existing_vpc_id == null && length(var.network_private_endpoints) > 0 ? 1 : 0

  vpc_id                     = local.vpc_id
  create_security_group      = true
  security_group_name        = "${var.name}-endpoints"
  security_group_description = "VPC endpoint default security group"
  security_group_rules = {
    ingress_https = {
      description = "HTTPS from VPC"
      cidr_blocks = [local.vpc_cidr]
    }
  }

  endpoints = { for endpoint_service in var.network_private_endpoints :
    endpoint_service => {
      service             = endpoint_service
      subnet_ids          = module.network[0].private_subnets
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

data "aws_route53_zone" "existing_public" {
  count   = var.existing_public_route53_zone_id != null ? 1 : 0
  zone_id = var.existing_public_route53_zone_id
}

data "aws_route53_zone" "existing_private" {
  count   = var.existing_private_route53_zone_id != null ? 1 : 0
  zone_id = var.existing_private_route53_zone_id
}

locals {
  # create a public zone if we're using external_dns with internet_facing LB
  # or creating a public ACM certificate
  create_public_zone = var.create_dns_zones && var.existing_public_route53_zone_id == null && ((var.external_dns && var.internet_facing_ingress_lb) || (var.create_acm_certificate && var.existing_acm_certificate_arn == ""))
  public_zone_id     = var.existing_public_route53_zone_id != null ? var.existing_public_route53_zone_id : try(module.public_dns[0].id, null)
  public_zone_arn    = try(data.aws_route53_zone.existing_public[0].arn, module.public_dns[0].arn, null)

  # create a private zone if we're using external_dns with an internal LB
  create_private_zone = var.create_dns_zones && var.existing_private_route53_zone_id == null && (var.external_dns && !var.internet_facing_ingress_lb)
  private_zone_id     = var.existing_private_route53_zone_id != null ? var.existing_private_route53_zone_id : try(module.private_dns[0].id, null)
  private_zone_arn    = try(data.aws_route53_zone.existing_private[0].arn, module.private_dns[0].arn, null)
}

module "public_dns" {
  source  = "terraform-aws-modules/route53/aws"
  version = "~> 6.0"
  count   = local.create_public_zone ? 1 : 0

  name          = var.domain_name
  comment       = "${var.domain_name} public zone"
  force_destroy = var.dns_zones_force_destroy

  tags = var.tags
}

module "private_dns" {
  source  = "terraform-aws-modules/route53/aws"
  version = "~> 6.0"
  count   = local.create_private_zone ? 1 : 0

  name          = var.domain_name
  comment       = "${var.domain_name} private zone"
  force_destroy = var.dns_zones_force_destroy
  vpc = {
    this = {
      vpc_id = local.vpc_id
    }
  }

  tags = var.tags
}


################################################################################
# ACM
################################################################################

locals {
  acm_certificate_arn = var.existing_acm_certificate_arn != null ? var.existing_acm_certificate_arn : try(module.acm[0].acm_certificate_arn, null)
}

module "acm" {
  source  = "terraform-aws-modules/acm/aws"
  version = "~> 5.0" # 6.0 requires TF >= 1.10
  count   = var.create_acm_certificate && var.existing_acm_certificate_arn == null ? 1 : 0

  domain_name = var.domain_name
  zone_id     = local.public_zone_id

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
# Storage
################################################################################

locals {
  s3_bucket_id = var.existing_s3_bucket_id != null ? var.existing_s3_bucket_id : try(module.storage[0].s3_bucket_id, null)
}

module "storage" {
  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "~> 5.0"
  count   = var.create_storage && var.existing_s3_bucket_id == null ? 1 : 0

  bucket_prefix = replace(var.name, "_", "-")
  force_destroy = var.s3_bucket_force_destroy

  tags = var.tags
}


################################################################################
# Container Registry
################################################################################

module "container_registry" {
  source = "terraform-aws-modules/ecr/aws"

  version  = "~> 3.0"
  for_each = var.create_container_registry ? var.ecr_repositories : []

  repository_name                   = "${var.name}/${each.key}"
  repository_read_write_access_arns = [local.app_role_arn]
  repository_image_scan_on_push     = var.ecr_repositories_scan_on_push
  repository_force_delete           = var.ecr_repositories_force_destroy
  create_lifecycle_policy           = false

  tags = var.tags
}


################################################################################
# Kubernetes
################################################################################

data "aws_eks_cluster" "existing" {
  count = var.existing_eks_cluster_name != null ? 1 : 0
  name  = var.existing_eks_cluster_name
}

locals {
  eks_cluster_name        = try(data.aws_eks_cluster.existing[0].name, module.kubernetes[0].cluster_name, null)
  eks_cluster_ca_data     = try(data.aws_eks_cluster.existing[0].certificate_authority[0].data, module.kubernetes[0].cluster_certificate_authority_data, "")
  eks_cluster_endpoint    = try(data.aws_eks_cluster.existing[0].endpoint, module.kubernetes[0].cluster_endpoint, "")
  eks_oidc_issuer_url     = try(data.aws_eks_cluster.existing[0].identity[0].oidc[0].issuer, module.kubernetes[0].cluster_oidc_issuer_url, null)
  kubernetes_node_subnets = var.existing_kubernetes_node_subnets != null ? var.existing_kubernetes_node_subnets : try(module.network[0].private_subnets, null)
}

module "kubernetes" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 21.0"
  count   = var.create_kubernetes_cluster && var.existing_eks_cluster_name == null ? 1 : 0

  name                         = var.name
  kubernetes_version           = var.kubernetes_cluster_version
  enable_irsa                  = var.kubernetes_enable_irsa
  encryption_config            = var.kubernetes_cluster_encryption_config
  enable_auto_mode_custom_tags = var.kubernetes_enable_auto_mode_custom_tags

  create_iam_role               = var.kubernetes_iam_role_arn == null
  iam_role_arn                  = var.kubernetes_iam_role_arn
  iam_role_name                 = var.kubernetes_iam_role_name
  iam_role_use_name_prefix      = var.kubernetes_iam_role_use_name_prefix
  iam_role_permissions_boundary = var.kubernetes_iam_role_permissions_boundary

  authentication_mode                      = var.kubernetes_authentication_mode
  enable_cluster_creator_admin_permissions = var.kubernetes_enable_cluster_creator_admin_permissions
  access_entries                           = var.kubernetes_cluster_access_entries

  vpc_id     = local.vpc_id
  subnet_ids = local.kubernetes_node_subnets

  endpoint_public_access       = var.kubernetes_cluster_endpoint_public_access
  endpoint_public_access_cidrs = var.kubernetes_cluster_endpoint_public_access_cidrs

  security_group_additional_rules = length(var.kubernetes_cluster_endpoint_private_access_cidrs) > 0 ? {
    ingress_custom_https = {
      description = "Custom hosts to control plane"
      protocol    = "tcp"
      from_port   = 443
      to_port     = 443
      type        = "ingress"
      cidr_blocks = var.kubernetes_cluster_endpoint_private_access_cidrs
    }
  } : {}

  addons = var.kubernetes_cluster_addons

  node_security_group_additional_rules         = var.kubernetes_node_security_group_additional_rules
  node_security_group_enable_recommended_rules = var.kubernetes_node_security_group_enable_recommended_rules

  eks_managed_node_groups = var.kubernetes_node_groups

  tags = var.tags
}

locals {
  # ASG tags for scaling to and from 0
  # represented as a tuple of objects in the form [{node_group, tag_key, tag_value}]
  node_group_asg_tags = flatten([
    for node_group_name, node_group_values in var.kubernetes_node_groups : concat(
      [
        for k, v in node_group_values.labels : {
          node_group = node_group_name
          tag_key    = "k8s.io/cluster-autoscaler/node-template/label/${k}"
          tag_value  = v
        }
      ],
      [
        for k, v in node_group_values.taints : {
          node_group = node_group_name
          tag_key    = "k8s.io/cluster-autoscaler/node-template/taint/${v.key}"
          tag_value  = "${v.value}:${v.effect}"
        }
      ]
    )
  ])
}

resource "aws_autoscaling_group_tag" "this" {
  for_each = var.create_kubernetes_cluster && var.existing_eks_cluster_name == null ? { for i, asg_tag in local.node_group_asg_tags : i => asg_tag } : {}

  autoscaling_group_name = module.kubernetes[0].eks_managed_node_groups[each.value.node_group].node_group_autoscaling_group_names[0]

  tag {
    key   = each.value.tag_key
    value = each.value.tag_value

    propagate_at_launch = true
  }
}


################################################################################
# App Identity
################################################################################

locals {
  app_role_arn = var.existing_app_role_arn != null ? var.existing_app_role_arn : try(module.app_identity[0].arn, null)
}

module "app_identity" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role"
  version = "~> 6.0"
  count   = var.create_app_identity ? 1 : 0

  name = "${var.name}-app-irsa"

  # trust
  enable_oidc            = true
  oidc_provider_urls     = [local.eks_oidc_issuer_url]
  oidc_wildcard_subjects = ["system:serviceaccount:${var.datarobot_namespace}:*"]
  oidc_audiences         = ["sts.amazonaws.com"]
  trust_policy_permissions = {
    emr = {
      actions = ["sts:AssumeRole"]
      principals = [{
        type        = "Service"
        identifiers = ["emr-serverless.amazonaws.com"]
      }]
    }
  }

  # managed policies
  policies = {
    ecr = "arn:${data.aws_partition.current.id}:iam::aws:policy/AmazonEC2ContainerRegistryPowerUser"
  }

  # inline policies
  create_inline_policy = true
  inline_policy_permissions = {
    s3bucket = {
      actions = [
        "s3:DeleteObject",
        "s3:Get*",
        "s3:PutObject",
        "s3:ReplicateDelete",
        "s3:ListMultipartUploadParts"
      ]
      resources = [
        "arn:${data.aws_partition.current.id}:s3:::${local.s3_bucket_id}",
        "arn:${data.aws_partition.current.id}:s3:::${local.s3_bucket_id}/*"
      ]
    }
    s3list = {
      actions = [
        "s3:ListBucket",
        "s3:ListBucketVersions",
        "s3:ListAllMyBuckets"
      ]
      resources = ["arn:${data.aws_partition.current.id}:s3:::*"]
    }
    sts = {
      actions = [
        "sts:AssumeRole"
      ]
      resources = ["arn:${data.aws_partition.current.id}:iam::${data.aws_caller_identity.current.account_id}:role/*"]
    }
  }

  tags = var.tags
}


################################################################################
# PostgreSQL
################################################################################

locals {
  postgres_subnets = var.existing_postgres_subnets != null ? var.existing_postgres_subnets : try(module.network[0].database_subnets, null)
}

module "postgres" {
  source = "./modules/postgres"
  count  = var.create_postgres ? 1 : 0

  name     = var.name
  vpc_id   = local.vpc_id
  vpc_cidr = local.vpc_cidr
  subnets  = local.postgres_subnets
  multi_az = local.multi_az

  postgres_engine_version          = var.postgres_engine_version
  postgres_instance_class          = var.postgres_instance_class
  postgres_allocated_storage       = var.postgres_allocated_storage
  postgres_max_allocated_storage   = var.postgres_max_allocated_storage
  postgres_backup_retention_period = var.postgres_backup_retention_period
  postgres_deletion_protection     = var.postgres_deletion_protection

  tags = var.tags
}


################################################################################
# Redis
################################################################################

locals {
  redis_subnets = var.existing_redis_subnets != null ? var.existing_redis_subnets : try(module.network[0].database_subnets, null)
}

module "redis" {
  source = "./modules/redis"
  count  = var.create_redis ? 1 : 0

  name     = var.name
  vpc_id   = local.vpc_id
  vpc_cidr = local.vpc_cidr
  subnets  = local.redis_subnets
  multi_az = local.multi_az

  redis_engine_version = var.redis_engine_version
  redis_node_type      = var.redis_node_type

  tags = var.tags
}


################################################################################
# MongoDB
################################################################################

provider "mongodbatlas" {
  public_key  = var.mongodb_atlas_public_key
  private_key = var.mongodb_atlas_private_key
}

locals {
  mongodb_subnets = var.existing_mongodb_subnets != null ? var.existing_mongodb_subnets : try(module.network[0].database_subnets, null)
}

module "mongodb" {
  source = "./modules/mongodb"
  count  = var.create_mongodb ? 1 : 0

  name     = var.name
  vpc_id   = local.vpc_id
  vpc_cidr = local.vpc_cidr
  subnets  = local.mongodb_subnets

  mongodb_version                    = var.mongodb_version
  atlas_org_id                       = var.mongodb_atlas_org_id
  termination_protection_enabled     = var.mongodb_termination_protection_enabled
  db_audit_enable                    = var.mongodb_audit_enable
  atlas_auto_scaling_disk_gb_enabled = var.mongodb_atlas_auto_scaling_disk_gb_enabled
  atlas_disk_size                    = var.mongodb_atlas_disk_size
  atlas_instance_type                = var.mongodb_atlas_instance_type
  mongodb_admin_username             = var.mongodb_admin_username
  mongodb_admin_arns                 = var.mongodb_admin_arns
  enable_slack_alerts                = var.mongodb_enable_slack_alerts
  slack_api_token                    = var.mongodb_slack_api_token
  slack_notification_channel         = var.mongodb_slack_notification_channel

  tags = var.tags
}


################################################################################
# Helm Charts
################################################################################

data "aws_eks_cluster_auth" "this" {
  count = var.create_kubernetes_cluster || var.existing_eks_cluster_name != null ? 1 : 0

  name = local.eks_cluster_name
}

provider "helm" {
  kubernetes = {
    host                   = local.eks_cluster_endpoint
    cluster_ca_certificate = base64decode(try(local.eks_cluster_ca_data, ""))
    token                  = try(data.aws_eks_cluster_auth.this[0].token, "")
  }
}

module "cluster_autoscaler" {
  source = "./modules/cluster-autoscaler"
  count  = var.install_helm_charts && var.cluster_autoscaler ? 1 : 0

  kubernetes_cluster_name = local.eks_cluster_name

  custom_values_templatefile = var.cluster_autoscaler_values
  custom_values_variables    = var.cluster_autoscaler_variables

  tags = var.tags

  depends_on = [module.aws_load_balancer_controller]
}

module "descheduler" {
  source = "./modules/descheduler"
  count  = var.install_helm_charts && var.descheduler ? 1 : 0

  custom_values_templatefile = var.descheduler_values
  custom_values_variables    = var.descheduler_variables
}

module "aws_ebs_csi_driver" {
  source = "./modules/aws-ebs-csi-driver"
  count  = var.install_helm_charts && var.aws_ebs_csi_driver ? 1 : 0

  kubernetes_cluster_name = local.eks_cluster_name

  custom_values_templatefile = var.aws_ebs_csi_driver_values
  custom_values_variables    = var.aws_ebs_csi_driver_variables

  tags = var.tags
}

module "aws_load_balancer_controller" {
  source = "./modules/aws-load-balancer-controller"
  count  = var.install_helm_charts && var.aws_load_balancer_controller ? 1 : 0

  kubernetes_cluster_name = local.eks_cluster_name
  vpc_id                  = local.vpc_id

  custom_values_templatefile = var.aws_load_balancer_controller_values
  custom_values_variables    = var.aws_load_balancer_controller_variables

  tags = var.tags
}

module "ingress_nginx" {
  source = "./modules/ingress-nginx"
  count  = var.install_helm_charts && var.ingress_nginx ? 1 : 0

  internet_facing_ingress_lb      = var.internet_facing_ingress_lb
  eks_cluster_name                = local.eks_cluster_name
  acm_certificate_arn             = local.acm_certificate_arn
  create_vpce_service             = var.create_ingress_vpce_service
  vpce_service_allowed_principals = var.ingress_vpce_service_allowed_principals
  vpce_service_private_dns_name   = var.domain_name

  custom_values_templatefile = var.ingress_nginx_values
  custom_values_variables    = var.ingress_nginx_variables

  tags = var.tags

  depends_on = [module.aws_load_balancer_controller]
}

module "cert_manager" {
  source = "./modules/cert-manager"
  count  = var.install_helm_charts && var.cert_manager ? 1 : 0

  kubernetes_cluster_name = local.eks_cluster_name
  route53_zone_arn        = local.public_zone_arn

  custom_values_templatefile = var.cert_manager_values
  custom_values_variables    = var.cert_manager_variables

  tags = var.tags

  depends_on = [module.aws_load_balancer_controller]
}

module "external_dns" {
  source = "./modules/external-dns"
  count  = var.install_helm_charts && var.external_dns ? 1 : 0

  kubernetes_cluster_name = local.eks_cluster_name
  route53_zone_arn        = var.internet_facing_ingress_lb ? local.public_zone_arn : local.private_zone_arn
  route53_zone_name       = var.domain_name

  custom_values_templatefile = var.external_dns_values
  custom_values_variables    = var.external_dns_variables

  tags = var.tags

  depends_on = [module.aws_load_balancer_controller]
}

module "nvidia_gpu_operator" {
  source = "./modules/nvidia-gpu-operator"
  count  = var.install_helm_charts && var.nvidia_gpu_operator ? 1 : 0

  custom_values_templatefile = var.nvidia_gpu_operator_values
  custom_values_variables    = var.nvidia_gpu_operator_variables
}

module "metrics_server" {
  source = "./modules/metrics-server"
  count  = var.install_helm_charts && var.metrics_server ? 1 : 0

  custom_values_templatefile = var.metrics_server_values
  custom_values_variables    = var.metrics_server_variables

  depends_on = [module.aws_load_balancer_controller]
}
