provider "aws" {
  region = "us-west-2"
}

locals {
  name = "datarobot"
}

module "datarobot_infra" {
  source = "../.."

  name        = local.name
  domain_name = "${local.name}.yourdomain.com"

  create_network            = true
  network_address_space     = "10.7.0.0/16"
  create_dns_zones          = true
  create_acm_certificate    = true
  create_encryption_key     = true
  create_storage            = true
  create_container_registry = true
  create_kubernetes_cluster = true
  create_app_identity       = true

  aws_load_balancer_controller = true
  cert_manager                 = true
  cluster_autoscaler           = true
  ebs_csi_driver               = true
  external_dns                 = true
  ingress_nginx                = true
  internet_facing_ingress_lb   = true
  nvidia_device_plugin         = true

  tags = {
    application = local.name
    environment = "dev"
    managed-by  = "terraform"
  }
}
