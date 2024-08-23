provider "aws" {
  region = "us-west-2"
}

locals {
  name     = "datarobot"
  app_fqdn = "${local.name}.yourdomain.com"
}

module "datarobot_infra" {
  source = "../.."

  name     = local.name
  app_fqdn = local.app_fqdn

  tags = {
    application = local.name
    environment = "dev"
    managed-by  = "terraform"
  }
}
