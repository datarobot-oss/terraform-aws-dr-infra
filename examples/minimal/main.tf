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

  tags = {
    application = local.name
    environment = "dev"
    managed-by  = "terraform"
  }
}
