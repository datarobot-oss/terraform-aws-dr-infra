provider "aws" {
  region = "us-west-2"
}

data "aws_caller_identity" "current" {}

locals {
  name                   = "datarobot"
  provisioner_private_ip = "10.0.0.99/32"
}

module "datarobot_infra" {
  source = "../.."

  ################################################################################
  # General
  ################################################################################
  name               = local.name
  domain_name        = "${local.name}.yourdomain.com"
  availability_zones = 2
  fips_enabled       = false
  tags = {
    application = local.name
    environment = "dev"
    managed-by  = "terraform"
  }

  ################################################################################
  # Network
  ################################################################################
  create_network                                 = true
  network_address_space                          = "10.7.0.0/16"
  network_private_endpoints                      = ["s3"]
  network_s3_private_dns_enabled                 = true
  network_enable_vpc_flow_logs                   = true
  network_cloudwatch_log_group_retention_in_days = 30

  ################################################################################
  # DNS
  ################################################################################
  create_dns_zones        = true
  dns_zones_force_destroy = true

  ################################################################################
  # ACM
  ################################################################################
  # bring your own certificate rather than using ACM by setting create_acm_certificate
  # to false, omitting existing_acm_certificate_arn, and updating ingress-nginx
  # values with controller.service.targetPorts.https = https
  create_acm_certificate = false

  ################################################################################
  # Storage
  ################################################################################
  create_storage          = true
  s3_bucket_force_destroy = true

  ################################################################################
  # Container Registry
  ################################################################################
  create_container_registry = true
  ecr_repositories = [
    "base-image",
    "custom-apps/managed-image",
    "custom-jobs/managed-image",
    "ephemeral-image",
    "managed-image",
    "services/custom-model-conversion",
    "spark-batch-image"
  ]
  ecr_repositories_scan_on_push  = false
  ecr_repositories_force_destroy = true

  ################################################################################
  # Kubernetes
  ################################################################################
  create_kubernetes_cluster      = true
  kubernetes_cluster_version     = "1.33"
  kubernetes_authentication_mode = "API_AND_CONFIG_MAP"
  kubernetes_enable_irsa         = true
  kubernetes_cluster_encryption_config = {
    resources = ["secrets"]
  }
  kubernetes_enable_auto_mode_custom_tags             = true
  kubernetes_iam_role_arn                             = null
  kubernetes_iam_role_name                            = null
  kubernetes_iam_role_use_name_prefix                 = true
  kubernetes_iam_role_permissions_boundary            = null
  kubernetes_enable_cluster_creator_admin_permissions = true
  # kubernetes_cluster_access_entries = {
  #   customadmin = {
  #     kubernetes_groups = []
  #     principal_arn     = "arn:aws:iam::12345678912:role/some-other-kubernetes-admin"

  #     policy_associations = {
  #       cluster_admin = {
  #         policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
  #         access_scope = {
  #           type = "cluster"
  #         }
  #       }
  #     }
  #   }
  # }
  kubernetes_cluster_endpoint_public_access        = false
  kubernetes_cluster_endpoint_public_access_cidrs  = []
  kubernetes_cluster_endpoint_private_access_cidrs = [local.provisioner_private_ip]
  kubernetes_cluster_addons = {
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
          ENABLE_PREFIX_DELEGATION = "true"
          WARM_PREFIX_TARGET       = "1"
        }
      })
    }
  }
  kubernetes_node_security_group_additional_rules         = {}
  kubernetes_node_security_group_enable_recommended_rules = true
  kubernetes_node_groups = {
    drcpu = {
      create         = true
      ami_type       = "AL2023_x86_64_STANDARD"
      instance_types = ["r6a.4xlarge", "r6i.4xlarge", "r5.4xlarge", "r4.4xlarge"]
      desired_size   = 2
      min_size       = 1
      max_size       = 10
      labels = {
        "datarobot.com/node-capability" = "cpu"
      }
      taints = {}
    }
    drgpu = {
      create         = true
      ami_type       = "AL2023_x86_64_NVIDIA"
      instance_types = ["g4dn.2xlarge"]
      desired_size   = 0
      min_size       = 0
      max_size       = 10
      labels = {
        "datarobot.com/node-capability" = "gpu"
        "datarobot.com/node-type"       = "on-demand"
        "datarobot.com/gpu-type"        = "nvidia-t4-2x"
      }
      taints = {
        nvidia_gpu = {
          key    = "nvidia.com/gpu"
          value  = "true"
          effect = "NO_SCHEDULE"
        }
      }
    }
  }


  ################################################################################
  # App Identity
  ################################################################################
  create_app_identity = true
  datarobot_namespace = "dr-app"

  ################################################################################
  # PostgreSQL
  ################################################################################
  create_postgres                  = true
  postgres_engine_version          = "13"
  postgres_instance_class          = "db.m6g.large"
  postgres_allocated_storage       = 20
  postgres_max_allocated_storage   = 500
  postgres_backup_retention_period = 7
  postgres_deletion_protection     = false

  ################################################################################
  # Redis
  ################################################################################
  create_redis         = true
  redis_engine_version = "7.1"
  redis_node_type      = "cache.t4g.medium"

  ################################################################################
  # MongoDB
  ################################################################################
  create_mongodb                             = true
  mongodb_version                            = "7.0"
  mongodb_atlas_org_id                       = "1a2b3c4d5e6f7g8h9i10j"
  mongodb_atlas_public_key                   = "atlas-public-key"
  mongodb_atlas_private_key                  = "atlas-private-key"
  mongodb_termination_protection_enabled     = false
  mongodb_audit_enable                       = true
  mongodb_admin_username                     = "pcs-mongodb"
  mongodb_admin_arns                         = [data.aws_caller_identity.current.arn]
  mongodb_atlas_auto_scaling_disk_gb_enabled = true
  mongodb_atlas_disk_size                    = 20
  mongodb_atlas_instance_type                = "M30"
  mongodb_enable_slack_alerts                = true
  mongodb_slack_api_token                    = "slack-api-token"
  mongodb_slack_notification_channel         = "#mongodb-atlas-notifications"

  ################################################################################
  # RabbitMQ
  ################################################################################
  create_rabbitmq                                 = true
  rabbitmq_engine_version                         = "3.13"
  rabbitmq_auto_minor_version_upgrade             = true
  rabbitmq_instance_type                          = "mq.m5.large"
  rabbitmq_authentication_strategy                = "simple"
  rabbitmq_username                               = "pcs-rabbitmq"
  rabbitmq_enable_cloudwatch_logs                 = true
  rabbitmq_cloudwatch_log_group_retention_in_days = 90

  ################################################################################
  # Helm Charts
  ################################################################################
  install_helm_charts = true

  ################################################################################
  # aws-ebs-csi-driver
  ################################################################################
  aws_ebs_csi_driver                  = true
  aws_ebs_csi_driver_values_overrides = file("${path.module}/templates/custom_aws_ebs_csi_driver_values.yaml")

  ################################################################################
  # cluster-autoscaler
  ################################################################################
  cluster_autoscaler                  = true
  cluster_autoscaler_values_overrides = file("${path.module}/templates/custom_cluster_autoscaler_values.yaml")

  ################################################################################
  # descheduler
  ################################################################################
  descheduler                  = true
  descheduler_values_overrides = file("${path.module}/templates/custom_descheduler_values.yaml")

  ################################################################################
  # aws-load-balancer-controller
  ################################################################################
  aws_load_balancer_controller                  = true
  aws_load_balancer_controller_values_overrides = file("${path.module}/templates/custom_aws_lb_controller_values.yaml")

  ################################################################################
  # ingress-nginx
  ################################################################################
  ingress_nginx                           = true
  internet_facing_ingress_lb              = false
  create_ingress_vpce_service             = true
  ingress_vpce_service_allowed_principals = ["arn:aws:iam::12345678910:root"]

  # in this case our custom values file override is formatted as a templatefile
  # so we can pass variables like our provisioner_private_ip to it.
  # https://developer.hashicorp.com/terraform/language/functions/templatefile
  ingress_nginx_values_overrides = templatefile("${path.module}/templates/custom_ingress_nginx_values.tftpl", {
    lb_source_ranges = [local.provisioner_private_ip]
  })

  ################################################################################
  # cert-manager
  ################################################################################
  cert_manager                  = true
  cert_manager_values_overrides = file("${path.module}/templates/custom_cert_manager_values.yaml")

  ################################################################################
  # external-dns
  ################################################################################
  external_dns                  = true
  external_dns_values_overrides = file("${path.module}/templates/custom_external_dns_values.yaml")

  ################################################################################
  # external-secrets
  ################################################################################
  external_secrets                      = true
  external_secrets_secrets_manager_arns = ["arn:aws:secretsmanager:*:*:secret:bar"]
  external_secrets_values_overrides     = "${path.module}/templates/custom_external_secrets_values.yaml"

  ################################################################################
  # nvidia-gpu-operator
  ################################################################################
  nvidia_gpu_operator                  = false
  nvidia_gpu_operator_values_overrides = file("${path.module}/templates/custom_nvidia_gpu_operator_plugin_values.yaml")

  ################################################################################
  # metrics-server
  ################################################################################
  metrics_server                  = true
  metrics_server_values_overrides = file("${path.module}/templates/custom_metrics_server_values.yaml")

  ################################################################################
  # cilium
  ################################################################################
  cilium                  = true
  cilium_values_overrides = file("${path.module}/templates/custom_cilium_values.yaml")
}
