provider "aws" {
  region = "us-east-1"
}

locals {
  name        = "datarobot"
  domain_name = "${local.name}.yourdomain.com"
  vpc_cidr    = "10.7.0.0/16"

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

  create_vpc               = true
  vpc_cidr                 = local.vpc_cidr
  create_dns_zone          = true
  create_acm_certificate   = true
  create_kms_key           = true
  create_s3_bucket         = true
  create_eks_cluster       = true
  create_eks_gpu_nodegroup = false
  create_app_irsa_role     = true

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

  install_cluster_autoscaler           = true
  install_ebs_csi_driver               = true
  ebs_csi_driver_kms_arn               = module.datarobot_infra.ebs_kms_key_arn
  install_aws_load_balancer_controller = true
  install_ingress_nginx                = true
  ingress_nginx_acm_certificate_arn    = module.datarobot_infra.acm_certificate_arn
  ingress_nginx_internet_facing        = true
  install_cert_manager                 = true
  cert_manager_hosted_zone_arns        = [module.datarobot_infra.public_route53_zone_arn]
  install_external_dns                 = true
  external_dns_hosted_zone_arn         = module.datarobot_infra.public_route53_zone_arn
  external_dns_hosted_zone_id          = module.datarobot_infra.public_route53_zone_id
  external_dns_hosted_zone_name        = local.domain_name

  tags = local.tags
}
