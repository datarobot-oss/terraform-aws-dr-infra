data "aws_caller_identity" "current" {}
data "aws_partition" "current" {}
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

locals {
  azs                         = slice(data.aws_availability_zones.available.names, 0, var.availability_zones)
  vpc_id                      = var.create_network && var.existing_vpc_id == null ? module.network[0].vpc_id : var.existing_vpc_id
  kubernetes_nodes_subnet_ids = var.create_network && length(var.existing_kubernetes_nodes_subnet_ids) == 0 ? module.network[0].private_subnets : var.existing_kubernetes_nodes_subnet_ids
}

module "network" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"
  count   = var.create_network && var.existing_vpc_id == null ? 1 : 0

  name = var.name
  cidr = var.network_address_space

  azs             = local.azs
  private_subnets = [for k, v in local.azs : cidrsubnet(var.network_address_space, 4, k)]
  public_subnets  = [for k, v in local.azs : cidrsubnet(var.network_address_space, 8, k + 48)]

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
  count   = var.create_network && var.existing_vpc_id == null && length(var.network_private_endpoints) > 0 ? 1 : 0

  vpc_id                     = local.vpc_id
  create_security_group      = true
  security_group_name        = "${var.name}-endpoints"
  security_group_description = "VPC endpoint default security group"
  security_group_rules = {
    ingress_https = {
      description = "HTTPS from VPC"
      cidr_blocks = [var.network_address_space]
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

data "aws_route53_zone" "public" {
  count   = var.existing_public_route53_zone_id != "" ? 1 : 0
  zone_id = var.existing_public_route53_zone_id
}

data "aws_route53_zone" "private" {
  count   = var.existing_private_route53_zone_id != "" ? 1 : 0
  zone_id = var.existing_private_route53_zone_id
}

locals {
  public_zone = {
    public = {
      domain_name   = var.domain_name
      comment       = "${var.domain_name} public zone"
      force_destroy = var.dns_zones_force_destroy
    }
  }
  private_zone = {
    private = {
      domain_name   = var.domain_name
      vpc           = [{ vpc_id = local.vpc_id }]
      comment       = "${var.domain_name} private zone"
      force_destroy = var.dns_zones_force_destroy
    }
  }

  # create a public zone if we're using external_dns with internet_facing LB
  # or creating a public ACM certificate
  create_public_zone = var.create_dns_zones && var.existing_public_route53_zone_id == "" && ((var.external_dns && var.internet_facing_ingress_lb) || (var.create_acm_certificate && var.existing_acm_certificate_arn == ""))
  public_zone_id     = local.create_public_zone ? module.dns[0].route53_zone_zone_id["public"] : var.existing_public_route53_zone_id
  public_zone_arn    = local.create_public_zone ? module.dns[0].route53_zone_zone_arn["public"] : try(data.aws_route53_zone.public[0].arn, "")

  # create a private zone if we're using external_dns with an internal LB
  create_private_zone = var.create_dns_zones && var.existing_private_route53_zone_id == "" && (var.external_dns && !var.internet_facing_ingress_lb)
  private_zone_arn    = local.create_private_zone ? module.dns[0].route53_zone_zone_arn["private"] : try(data.aws_route53_zone.private[0].arn, "")
}

module "dns" {
  source  = "terraform-aws-modules/route53/aws//modules/zones"
  version = "~> 3.0"
  count   = local.create_public_zone || local.create_private_zone == "" ? 1 : 0

  zones = merge(
    local.create_private_zone ? local.private_zone : {},
    local.create_public_zone ? local.public_zone : {}
  )

  tags = var.tags
}


################################################################################
# ACM
################################################################################

locals {
  acm_certificate_arn = var.create_acm_certificate && var.existing_acm_certificate_arn == "" ? module.acm[0].acm_certificate_arn : var.existing_acm_certificate_arn
}

module "acm" {
  source  = "terraform-aws-modules/acm/aws"
  version = "~> 4.0"
  count   = var.create_acm_certificate && var.existing_acm_certificate_arn == "" ? 1 : 0

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
# Encryption Key
################################################################################

locals {
  encryption_key_arn = var.create_encryption_key && var.existing_kms_key_arn == "" ? module.encryption_key[0].key_arn : var.existing_kms_key_arn
}

module "encryption_key" {
  source  = "terraform-aws-modules/kms/aws"
  version = "~> 3.0"
  count   = var.create_encryption_key && var.existing_kms_key_arn == "" ? 1 : 0

  description = "Ec2 AutoScaling key usage"
  key_usage   = "ENCRYPT_DECRYPT"

  key_administrators                = [data.aws_caller_identity.current.arn]
  key_service_roles_for_autoscaling = ["arn:${data.aws_partition.current.id}:iam::${data.aws_caller_identity.current.account_id}:role/aws-service-role/autoscaling.amazonaws.com/AWSServiceRoleForAutoScaling"]

  aliases                 = ["datarobot/ebs"]
  aliases_use_name_prefix = true

  tags = var.tags
}


################################################################################
# Storage
################################################################################

locals {
  s3_bucket_id = var.create_storage && var.existing_s3_bucket_id == "" ? module.storage[0].s3_bucket_id : var.existing_s3_bucket_id
}

module "storage" {
  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "~> 4.0"
  count   = var.create_storage && var.existing_s3_bucket_id == "" ? 1 : 0

  bucket_prefix = replace(var.name, "_", "-")
  force_destroy = var.s3_bucket_force_destroy

  tags = var.tags
}


################################################################################
# Container Registry
################################################################################

module "container_registry" {
  source   = "terraform-aws-modules/ecr/aws"
  version  = "~> 2.0"
  for_each = var.create_container_registry ? var.ecr_repositories : []

  repository_name               = "${var.name}/${each.key}"
  repository_image_scan_on_push = false
  repository_force_delete       = var.ecr_repositories_force_destroy
  attach_repository_policy      = false
  create_lifecycle_policy       = false

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
  eks_cluster_name            = try(data.aws_eks_cluster.existing[0].name, module.kubernetes[0].cluster_name, "")
  eks_cluster_ca_data         = try(data.aws_eks_cluster.existing[0].certificate_authority[0].data, module.kubernetes[0].cluster_certificate_authority_data, "")
  eks_cluster_endpoint        = try(data.aws_eks_cluster.existing[0].endpoint, module.kubernetes[0].cluster_endpoint, "")
  eks_cluster_oidc_issuer_url = try(data.aws_eks_cluster.existing[0].identity[0].oidc[0].issuer, module.kubernetes[0].cluster_oidc_issuer_url, "")

  # create each node group in each AZ
  node_groups = merge([
    for az in local.azs : {
      for node_group_name, node_group_values in var.kubernetes_node_groups : "${node_group_name}-${substr(az, -1, -1)}" => merge(
        {
          create_placement_group = true
          placement_group_az     = az
        },
        node_group_values
      )
  }]...)

  # ASG tags for scaling to and from 0
  # represented as a tuple of objects in the form [{node_group, tag_key, tag_value}]
  node_group_asg_tags = flatten([
    for node_group_name, node_group_values in local.node_groups : concat(
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

module "kubernetes" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.0"
  count   = var.create_kubernetes_cluster && var.existing_eks_cluster_name == null ? 1 : 0

  cluster_name                 = var.name
  cluster_version              = var.kubernetes_cluster_version
  enable_irsa                  = var.kubernetes_enable_irsa
  cluster_encryption_config    = var.kubernetes_cluster_encryption_config
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
  subnet_ids = local.kubernetes_nodes_subnet_ids

  cluster_endpoint_public_access       = var.kubernetes_cluster_endpoint_public_access
  cluster_endpoint_public_access_cidrs = var.kubernetes_cluster_endpoint_public_access_cidrs

  cluster_security_group_additional_rules = length(var.kubernetes_cluster_endpoint_private_access_cidrs) != 0 ? {
    ingress_custom_https = {
      description = "Custom hosts to control plane"
      protocol    = "tcp"
      from_port   = 443
      to_port     = 443
      type        = "ingress"
      cidr_blocks = var.kubernetes_cluster_endpoint_private_access_cidrs
    }
  } : {}

  bootstrap_self_managed_addons = var.kubernetes_bootstrap_self_managed_addons
  cluster_addons                = var.kubernetes_cluster_addons

  node_security_group_additional_rules         = var.kubernetes_node_security_group_additional_rules
  node_security_group_enable_recommended_rules = var.kubernetes_node_security_group_enable_recommended_rules

  eks_managed_node_group_defaults = merge(
    {
      block_device_mappings = {
        xvda = {
          device_name = "/dev/xvda"
          ebs = {
            encrypted   = var.create_encryption_key || var.existing_kms_key_arn != ""
            kms_key_id  = local.encryption_key_arn
            volume_size = 200
          }
        }
      }
    },
    var.kubernetes_node_group_defaults
  )

  eks_managed_node_groups = local.node_groups

  tags = var.tags
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

module "app_identity" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-assumable-role-with-oidc"
  version = "~> 5.0"
  count   = var.create_app_identity ? 1 : 0

  create_role = true
  role_name   = "${var.name}-app-irsa"

  provider_url                 = replace(local.eks_cluster_oidc_issuer_url, "https://", "")
  oidc_subjects_with_wildcards = ["system:serviceaccount:${var.datarobot_namespace}:*"]

  role_policy_arns = [
    "arn:${data.aws_partition.current.id}:iam::aws:policy/AmazonEC2ContainerRegistryPowerUser"
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
        "arn:${data.aws_partition.current.id}:s3:::${local.s3_bucket_id}/*",
        "arn:${data.aws_partition.current.id}:s3:::${local.s3_bucket_id}"
      ]
    },
    {
      sid = "AllowListBuckets"
      actions = [
        "s3:ListBucket",
        "s3:ListBucketVersions",
        "s3:ListAllMyBuckets"
      ]
      resources = ["arn:${data.aws_partition.current.id}:s3:::*"]
    }
  ]

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
    host                   = try(local.eks_cluster_endpoint, "")
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
  aws_ebs_csi_kms_arn     = local.encryption_key_arn

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

  acm_certificate_arn        = local.acm_certificate_arn
  internet_facing_ingress_lb = var.internet_facing_ingress_lb

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

module "nvidia_device_plugin" {
  source = "./modules/nvidia-device-plugin"
  count  = var.install_helm_charts && var.nvidia_device_plugin ? 1 : 0

  custom_values_templatefile = var.nvidia_device_plugin_values
  custom_values_variables    = var.nvidia_device_plugin_variables
}

module "metrics_server" {
  source = "./modules/metrics-server"
  count  = var.install_helm_charts && var.metrics_server ? 1 : 0

  custom_values_templatefile = var.metrics_server_values
  custom_values_variables    = var.metrics_server_variables
}
