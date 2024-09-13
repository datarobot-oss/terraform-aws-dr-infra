provider "aws" {
  region = "us-east-1"
}

locals {
  name        = "datarobot"
  domain_name = "${local.name}.yourdomain.com"

  tags = {
    application = local.name
    environment = "dev"
    managed-by  = "terraform"
  }
}

module "datarobot_infra" {
  source = "../.."

  name        = local.name
  domain_name = local.domain_name

  tags = local.tags
}


data "aws_eks_cluster_auth" "this" {
  name = module.datarobot_infra.eks_cluster_name
}

provider "helm" {
  kubernetes {
    host                   = module.datarobot_infra.eks_cluster_endpoint
    cluster_ca_certificate = base64decode(module.datarobot_infra.eks_cluster_certificate_authority_data)
    token                  = data.aws_eks_cluster_auth.this.token
  }
}

module "datarobot_amenities" {
  source = "../../modules/amenities"

  eks_cluster_name = module.datarobot_infra.eks_cluster_name
  vpc_id           = module.datarobot_infra.vpc_id

  ebs_csi_driver_kms_arn            = module.datarobot_infra.ebs_kms_key_arn
  ingress_nginx_acm_certificate_arn = module.datarobot_infra.acm_certificate_arn
  cert_manager_hosted_zone_arns     = [module.datarobot_infra.public_route53_zone_arn]
  external_dns_hosted_zone_arn      = module.datarobot_infra.public_route53_zone_arn
  external_dns_hosted_zone_id       = module.datarobot_infra.public_route53_zone_id
  external_dns_hosted_zone_name     = local.domain_name

  tags = local.tags
}
