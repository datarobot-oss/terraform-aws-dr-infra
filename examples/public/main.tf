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

  container_registry_repos_force_destroy = !local.is_prod
  dns_zone_force_destroy                 = !local.is_prod
  storage_force_destroy                  = !local.is_prod

  # Allow traffic from VPC to AWS services to flow via the public internet
  # as a cost-saving measure, rather than provisioning VPC endpoints
  # for all services used by the application.
  network_endpoints = []

  tags = merge(
    {
      app         = var.name
      environment = var.environment
    },
    var.tags
  )
}
