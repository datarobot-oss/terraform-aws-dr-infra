provider "aws" {
  region = "us-west-2"
}

locals {
  name                  = "datarobot"
  provisioner_public_ip = "132.132.132.132/32"
}

module "datarobot_infra" {
  # source = "datarobot-oss/dr-infra/aws"
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
  # to false and not specifying an existing_acm_certificate_arn
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
  create_kubernetes_cluster  = true
  kubernetes_cluster_version = "1.30"
  kubernetes_cluster_access_entries = {
    customadmin = {
      kubernetes_groups = []
      principal_arn     = "arn:aws:iam::12345678912:role/custom-kubernetes-admin"

      policy_associations = {
        cluster_admin = {
          policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
          access_scope = {
            type = "cluster"
          }
        }
      }
    }
  }
  kubernetes_cluster_endpoint_public_access        = true
  kubernetes_cluster_endpoint_public_access_cidrs  = [local.provisioner_public_ip]
  kubernetes_cluster_endpoint_private_access_cidrs = []
  kubernetes_primary_nodegroup_name                = "primary"
  kubernetes_primary_nodegroup_ami_type            = "AL2023_x86_64_STANDARD"
  kubernetes_primary_nodegroup_instance_types      = ["r6a.4xlarge"]
  kubernetes_primary_nodegroup_desired_size        = 5
  kubernetes_primary_nodegroup_min_size            = 3
  kubernetes_primary_nodegroup_max_size            = 10
  kubernetes_primary_nodegroup_labels              = {}
  kubernetes_primary_nodegroup_taints              = {}
  kubernetes_gpu_nodegroup_name                    = "gpu"
  kubernetes_gpu_nodegroup_ami_type                = "AL2_x86_64_GPU"
  kubernetes_gpu_nodegroup_instance_types          = ["g4dn.2xlarge"]
  kubernetes_gpu_nodegroup_desired_size            = 0
  kubernetes_gpu_nodegroup_min_size                = 0
  kubernetes_gpu_nodegroup_max_size                = 10
  kubernetes_gpu_nodegroup_labels = {
    "datarobot.com/node-capability" = "gpu"
  }
  kubernetes_gpu_nodegroup_taints = {
    nvidia_gpu = {
      key    = "nvidia.com/gpu"
      effect = "NO_SCHEDULE"
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
}
