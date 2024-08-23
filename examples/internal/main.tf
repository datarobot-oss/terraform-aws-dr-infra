provider "aws" {
  region = "us-west-2"
}

locals {
  name     = "datarobot"
  app_fqdn = "${local.name}.yourdomain.com"

  vpc_id              = "<your-vpc-id>"
  eks_subnet_ids      = ["<subnet-1-id>", "<subnet-2-id>", "<subnet-3-id>"]
  route53_zone_id     = "<route53-zone-id>"
  acm_certificate_arn = "<acm-certificate-arn>"
}

module "datarobot_infra" {
  source = "../.."

  name     = local.name
  app_fqdn = local.app_fqdn

  create_vpc               = false
  vpc_id                   = local.vpc_id
  eks_subnet_ids           = local.eks_subnet_ids
  create_dns_zone          = false
  route53_zone_id          = local.route53_zone_id
  create_acm_certificate   = false
  acm_certificate_arn      = local.acm_certificate_arn
  eks_create_gpu_nodegroup = false

  internet_facing_ingress_lb = false

  tags = {
    application = local.name
    environment = "dev"
    managed-by  = "terraform"
  }
}
