provider "aws" {}

locals {
  name = "datarobot"
}

module "datarobot-infra" {
  source = "../.."

  name = local.name
  tags = {
    datarobot-app = local.name
    managed-by = "terraform"
  }
}
