provider "aws" {
  region              = var.region
  allowed_account_ids = [var.account_id]
}

locals {
  is_prod = var.environment == "prod"
}

module "datarobot_infra" {
  source = "../.."

  name                                   = var.name
  dns_zone_name                          = var.domain_name
  cert_manager_letsencrypt_email_address = var.email_address

  existing_vpc_id = var.existing_vpc_id

  container_registry_repos_force_destroy = !local.is_prod
  dns_zone_force_destroy                 = !local.is_prod
  storage_force_destroy                  = !local.is_prod

  # When kubernetes_cluster_endpoint_public_access is false, the host running "terraform apply"
  # must be provided access access the cluster private API endpoint in order to install helm charts.
  kubernetes_cluster_endpoint_public_access        = false
  kubernetes_cluster_endpoint_private_access_cidrs = ["${var.provisioner_ip}/32"]

  internet_facing_ingress_lb = false
  # Allow a CIDR to access the internal ingress load balancer
  ingress_nginx_values_overrides = <<-EOT
    controller:
      service:
        loadBalancerSourceRanges:
          - "${var.ingress_allowed_cidr}"
  EOT

  tags = merge(
    {
      app         = var.name
      environment = var.environment
    },
    var.tags
  )
}
