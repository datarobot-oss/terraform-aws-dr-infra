provider "aws" {
  region = "us-west-2"
}

locals {
  name                  = "datarobot"
  provisioner_public_ip = "132.132.132.132/32"
}

module "datarobot_infra" {
  source = "../.."

  ################################################################################
  # General
  ################################################################################
  name        = local.name
  domain_name = "${local.name}.yourdomain.com"
  tags = {
    application = local.name
    environment = "dev"
    managed-by  = "terraform"
  }

  ################################################################################
  # Network
  ################################################################################
  create_network            = true
  network_address_space     = "10.7.0.0/16"
  network_private_endpoints = ["s3"]

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
  # Encryption Key
  ################################################################################
  create_encryption_key = true

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
    "ephemeral-image",
    "managed-image",
    "custom-apps-managed-image"
  ]
  ecr_repositories_force_destroy = true

  ################################################################################
  # Kubernetes
  ################################################################################
  create_kubernetes_cluster      = true
  kubernetes_cluster_version     = "1.32"
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
  kubernetes_cluster_endpoint_public_access        = true
  kubernetes_cluster_endpoint_public_access_cidrs  = [local.provisioner_public_ip]
  kubernetes_cluster_endpoint_private_access_cidrs = []
  kubernetes_bootstrap_self_managed_addons         = false
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
  kubernetes_node_group_defaults = {}
  kubernetes_node_groups = {
    datarobot-cpu = {
      ami_type       = "AL2023_x86_64_STANDARD"
      instance_types = ["r6a.4xlarge", "r6i.4xlarge", "r5.4xlarge", "r4.4xlarge"]
      desired_size   = 1
      min_size       = 1
      max_size       = 10
      labels = {
        "datarobot.com/node-capability" = "cpu"
      }
      taints = {}
    }
    datarobot-gpu = {
      ami_type       = "AL2023_x86_64_NVIDIA"
      instance_types = ["g4dn.2xlarge"]
      desired_size   = 0
      min_size       = 0
      max_size       = 10
      labels = {
        "datarobot.com/node-capability" = "gpu"
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
  # aws-ebs-csi-driver
  ################################################################################
  ebs_csi_driver           = true
  ebs_csi_driver_values    = "${path.module}/templates/custom_ebs_csi_driver_values.yaml"
  ebs_csi_driver_variables = {}

  ################################################################################
  # cluster-autoscaler
  ################################################################################
  cluster_autoscaler           = true
  cluster_autoscaler_values    = "${path.module}/templates/custom_cluster_autoscaler_values.yaml"
  cluster_autoscaler_variables = {}

  ################################################################################
  # descheduler
  ################################################################################
  descheduler           = true
  descheduler_values    = "${path.module}/templates/custom_descheduler_values.yaml"
  descheduler_variables = {}

  ################################################################################
  # aws-load-balancer-controller
  ################################################################################
  aws_load_balancer_controller           = true
  aws_load_balancer_controller_values    = "${path.module}/templates/custom_aws_lb_controller_values.yaml"
  aws_load_balancer_controller_variables = {}

  ################################################################################
  # ingress-nginx
  ################################################################################
  ingress_nginx              = true
  internet_facing_ingress_lb = true

  # in this case our custom values file override is formatted as a templatefile
  # so we can pass variables like our provisioner_public_ip to it.
  # https://developer.hashicorp.com/terraform/language/functions/templatefile
  ingress_nginx_values = "${path.module}/templates/custom_ingress_nginx_values.tftpl"
  ingress_nginx_variables = {
    lb_source_ranges = [local.provisioner_public_ip]
  }

  ################################################################################
  # cert-manager
  ################################################################################
  cert_manager           = true
  cert_manager_values    = "${path.module}/templates/custom_cert_manager_values.yaml"
  cert_manager_variables = {}

  ################################################################################
  # external-dns
  ################################################################################
  external_dns           = true
  external_dns_values    = "${path.module}/templates/custom_external_dns_values.yaml"
  external_dns_variables = {}

  ################################################################################
  # nvidia-device-plugin
  ################################################################################
  nvidia_device_plugin           = true
  nvidia_device_plugin_values    = "${path.module}/templates/custom_nvidia_device_plugin_values.yaml"
  nvidia_device_plugin_variables = {}


  ################################################################################
  # metrics-server
  ################################################################################
  metrics_server           = true
  metrics_server_values    = "${path.module}/templates/custom_metrics_server_values.yaml"
  metrics_server_variables = {}
}
