data "aws_availability_zones" "available" {}

data "aws_caller_identity" "current" {}


################################################################################
# Network
################################################################################

locals {
  azs                         = slice(data.aws_availability_zones.available.names, 0, 3)
  vpc_id                      = var.create_network && var.existing_vpc_id == "" ? module.network[0].vpc_id : var.existing_vpc_id
  kubernetes_nodes_subnet_ids = var.create_network && length(var.existing_kubernetes_nodes_subnet_id) == 0 ? module.network[0].private_subnets : var.existing_kubernetes_nodes_subnet_id
}

module "network" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"
  count   = var.create_network && var.existing_vpc_id == "" ? 1 : 0

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
  count   = var.create_network && var.existing_vpc_id == "" && length(var.network_private_endpoints) > 0 ? 1 : 0

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
  key_service_roles_for_autoscaling = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/aws-service-role/autoscaling.amazonaws.com/AWSServiceRoleForAutoScaling"]

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
  eks_cluster_name            = try(data.aws_eks_cluster.existing[0].name, module.kubernetes[0].cluster_name, null)
  eks_cluster_ca_data         = try(data.aws_eks_cluster.existing[0].certificate_authority[0].data, module.kubernetes[0].cluster_certificate_authority_data, null)
  eks_cluster_endpoint        = try(data.aws_eks_cluster.existing[0].endpoint, module.kubernetes[0].cluster_endpoint, null)
  eks_cluster_oidc_issuer_url = try(data.aws_eks_cluster.existing[0].identity[0].oidc[0].issuer, module.kubernetes[0].cluster_oidc_issuer_url, null)

  primary_nodegroups = { for az in local.azs : "${var.kubernetes_primary_nodegroup_name}-${az}" => {
    create_placement_group = true
    placement_group_az     = az
    ami_type               = var.kubernetes_primary_nodegroup_ami_type
    instance_types         = var.kubernetes_primary_nodegroup_instance_types
    min_size               = var.kubernetes_primary_nodegroup_min_size
    max_size               = var.kubernetes_primary_nodegroup_max_size
    desired_size           = var.kubernetes_primary_nodegroup_desired_size
    labels                 = var.kubernetes_primary_nodegroup_labels
    taints                 = var.kubernetes_primary_nodegroup_taints
  } }

  primary_nodegroup_asg_tags = flatten([
    for nodegroup_name, nodegroup in local.primary_nodegroups : concat(
      [
        for k, v in var.kubernetes_primary_nodegroup_labels : {
          nodegroup_name = nodegroup_name
          key            = "k8s.io/cluster-autoscaler/node-template/label/${k}"
          value          = v
        }
      ],
      [
        for k, v in var.kubernetes_primary_nodegroup_taints : {
          nodegroup_name = nodegroup_name
          key            = "k8s.io/cluster-autoscaler/node-template/taint/${v.key}"
          value          = "${v.value}:${v.effect}"
        }
    ])
  ])

  gpu_nodegroups = { for az in local.azs : "${var.kubernetes_gpu_nodegroup_name}-${az}" => {
    create_placement_group = true
    placement_group_az     = az
    ami_type               = var.kubernetes_gpu_nodegroup_ami_type
    instance_types         = var.kubernetes_gpu_nodegroup_instance_types
    min_size               = var.kubernetes_gpu_nodegroup_min_size
    max_size               = var.kubernetes_gpu_nodegroup_max_size
    desired_size           = var.kubernetes_gpu_nodegroup_desired_size
    labels                 = var.kubernetes_gpu_nodegroup_labels
    taints                 = var.kubernetes_gpu_nodegroup_taints
  } }

  gpu_nodegroup_asg_tags = flatten([
    for nodegroup_name, nodegroup in local.gpu_nodegroups : concat(
      [
        for k, v in var.kubernetes_gpu_nodegroup_labels : {
          nodegroup_name = nodegroup_name
          key            = "k8s.io/cluster-autoscaler/node-template/label/${k}"
          value          = v
        }
      ],
      [
        for k, v in var.kubernetes_gpu_nodegroup_taints : {
          nodegroup_name = nodegroup_name
          key            = "k8s.io/cluster-autoscaler/node-template/taint/${v.key}"
          value          = "${v.value}:${v.effect}"
        }
      ]
    )
  ])

  # list of objects in the form of {nodegroup_name, key, value}
  asg_tags = concat(local.primary_nodegroup_asg_tags, local.gpu_nodegroup_asg_tags)
}

module "aws_vpc_cni_ipv4_pod_identity" {
  source  = "terraform-aws-modules/eks-pod-identity/aws"
  version = "~> 1.0"
  count   = var.create_kubernetes_cluster && var.existing_eks_cluster_name == null ? 1 : 0

  name = "aws-vpc-cni-ipv4"

  attach_aws_vpc_cni_policy = true
  aws_vpc_cni_enable_ipv4   = true

  tags = var.tags
}

module "kubernetes" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.0"
  count   = var.create_kubernetes_cluster && var.existing_eks_cluster_name == null ? 1 : 0

  cluster_name    = var.name
  cluster_version = var.kubernetes_cluster_version

  cluster_addons = {
    coredns = {
      most_recent = true
    }
    eks-pod-identity-agent = {
      most_recent    = true
      before_compute = true
    }
    kube-proxy = {
      most_recent = true
    }
    vpc-cni = {
      most_recent    = true
      before_compute = true

      configuration_values = jsonencode({
        enableNetworkPolicy = "true"
        env = {
          # Reference docs https://docs.aws.amazon.com/eks/latest/userguide/cni-increase-ip-addresses.html
          ENABLE_PREFIX_DELEGATION = "true"
          WARM_PREFIX_TARGET       = "1"
        }
      })

      pod_identity_association = [{
        role_arn        = module.aws_vpc_cni_ipv4_pod_identity[0].iam_role_arn
        service_account = "aws-node"
      }]
    }
  }

  enable_cluster_creator_admin_permissions = true
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

  eks_managed_node_group_defaults = {
    block_device_mappings = {
      xvda = {
        device_name = "/dev/xvda"
        ebs = {
          delete_on_termination = true
          encrypted             = var.create_encryption_key || var.existing_kms_key_arn != ""
          iops                  = 2000
          kms_key_id            = local.encryption_key_arn
          volume_size           = 200
          volume_type           = "gp3"
        }
      }
    }
  }

  eks_managed_node_groups = merge(local.primary_nodegroups, local.gpu_nodegroups)

  tags = var.tags
}

resource "aws_autoscaling_group_tag" "this" {
  for_each = var.create_kubernetes_cluster && var.existing_eks_cluster_name == null ? { for i, asg_tag in local.asg_tags : i => asg_tag } : {}

  autoscaling_group_name = module.kubernetes[0].eks_managed_node_groups[each.value.nodegroup_name].node_group_autoscaling_group_names[0]

  tag {
    key   = each.value.key
    value = each.value.value

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
# Helm Charts
################################################################################

data "aws_eks_cluster_auth" "this" {
  count = var.create_kubernetes_cluster || var.existing_eks_cluster_name != null ? 1 : 0

  name = local.eks_cluster_name
}

provider "helm" {
  kubernetes {
    host                   = try(local.eks_cluster_endpoint, "")
    cluster_ca_certificate = base64decode(try(local.eks_cluster_ca_data, ""))
    token                  = try(data.aws_eks_cluster_auth.this[0].token, "")
  }
}


module "cluster_autoscaler" {
  source = "./modules/cluster-autoscaler"
  count  = var.cluster_autoscaler ? 1 : 0

  kubernetes_cluster_name = local.eks_cluster_name

  custom_values_templatefile = var.cluster_autoscaler_values
  custom_values_variables    = var.cluster_autoscaler_variables

  tags = var.tags
}

module "descheduler" {
  source = "./modules/descheduler"
  count  = var.descheduler ? 1 : 0

  custom_values_templatefile = var.descheduler_values
  custom_values_variables    = var.descheduler_variables
}

module "ebs_csi_driver" {
  source = "./modules/ebs-csi-driver"
  count  = var.ebs_csi_driver ? 1 : 0

  kubernetes_cluster_name = local.eks_cluster_name
  aws_ebs_csi_kms_arn     = local.encryption_key_arn

  custom_values_templatefile = var.ebs_csi_driver_values
  custom_values_variables    = var.ebs_csi_driver_variables

  tags = var.tags
}


module "aws_load_balancer_controller" {
  source = "./modules/aws-load-balancer-controller"
  count  = var.aws_load_balancer_controller ? 1 : 0

  kubernetes_cluster_name = local.eks_cluster_name
  vpc_id                  = local.vpc_id

  custom_values_templatefile = var.aws_load_balancer_controller_values
  custom_values_variables    = var.aws_load_balancer_controller_variables

  tags = var.tags
}


module "ingress_nginx" {
  source = "./modules/ingress-nginx"
  count  = var.ingress_nginx ? 1 : 0

  acm_certificate_arn        = local.acm_certificate_arn
  internet_facing_ingress_lb = var.internet_facing_ingress_lb

  custom_values_templatefile = var.ingress_nginx_values
  custom_values_variables    = var.ingress_nginx_variables

  tags = var.tags

  depends_on = [module.aws_load_balancer_controller]
}


module "cert_manager" {
  source = "./modules/cert-manager"
  count  = var.cert_manager ? 1 : 0

  kubernetes_cluster_name = local.eks_cluster_name
  route53_zone_arn        = local.public_zone_arn

  custom_values_templatefile = var.cert_manager_values
  custom_values_variables    = var.cert_manager_variables

  tags = var.tags

  depends_on = [module.aws_load_balancer_controller]
}

module "external_dns" {
  source = "./modules/external-dns"
  count  = var.external_dns ? 1 : 0

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
  count  = var.nvidia_device_plugin ? 1 : 0

  custom_values_templatefile = var.nvidia_device_plugin_values
  custom_values_variables    = var.nvidia_device_plugin_variables
}

module "metrics_server" {
  source = "./modules/metrics-server"
  count  = var.metrics_server ? 1 : 0

  custom_values_templatefile = var.metrics_server_values
  custom_values_variables    = var.metrics_server_variables
}
