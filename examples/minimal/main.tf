provider "aws" {
  region = "us-west-2"
}

locals {
  name        = "datarobot"
  domain_name = "${local.name}.yourdomain.com"
}

module "datarobot_infra" {
  source = "../.."

  name        = local.name
  domain_name = local.domain_name

  tags = {
    application = local.name
    environment = "dev"
    managed-by  = "terraform"
  }
}
