provider "aws" {
  region = local.region
}

data "aws_caller_identity" "current" {}

locals {
  region      = "us-west-2"
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

resource "local_sensitive_file" "datarobot_prime_values" {
  filename = "${path.module}/datarobot_prime_values.yaml"
  content = templatefile("${path.module}/datarobot_prime_values.tftpl", {
    app_role_arn           = module.datarobot_infra.app_role_arn
    domain_name            = local.domain_name
    pull_registry_username = var.pull_registry_username
    pull_registry_password = var.pull_registry_password
    s3_bucket              = module.datarobot_infra.s3_bucket_id
    region                 = local.region
    ibs_registry           = "${data.aws_caller_identity.current.account_id}.dkr.ecr.${local.region}.amazonaws.com"
    ibs_repository         = local.name
    datarobot_license      = var.datarobot_license
  })
}
