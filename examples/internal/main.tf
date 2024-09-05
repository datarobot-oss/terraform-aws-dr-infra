provider "aws" {
  region = "us-west-2"
}

locals {
  name        = "datarobot"
  domain_name = "${local.name}.yourdomain.com"

  vpc_id              = "vpc-1234556abcdef"
  eks_subnet_ids      = ["subnet-abcde012", "subnet-bcde012a", "subnet-fghi345a"]
  provisioner_ip      = "10.0.0.99"
  route53_zone_id     = "Z06110132R7HO9BLI64XY"
  acm_certificate_arn = "arn:aws:acm:us-west-2:000000000000:certificate/00000000-0000-0000-0000-000000000000"
}

module "datarobot_infra" {
  source = "../.."

  name        = local.name
  domain_name = local.domain_name

  create_vpc                                = false
  vpc_id                                    = local.vpc_id
  eks_subnet_ids                            = local.eks_subnet_ids
  eks_cluster_endpoint_public_access        = false
  eks_cluster_endpoint_private_access_cidrs = ["${local.provisioner_ip}/32"]
  create_dns_zone                           = false
  route53_zone_id                           = local.route53_zone_id
  create_acm_certificate                    = false
  acm_certificate_arn                       = local.acm_certificate_arn
  create_eks_gpu_nodegroup                  = false

  internet_facing_ingress_lb = false

  tags = {
    application = local.name
    environment = "dev"
    managed-by  = "terraform"
  }
}
