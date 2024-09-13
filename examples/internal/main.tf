provider "aws" {
  region = "us-east-1"
}

locals {
  name        = "datarobot"
  domain_name = "${local.name}.yourdomain.com"

  vpc_id              = "vpc-0a2821c4c7ef62b88"
  eks_subnet_ids      = ["subnet-00b2e232a2048dabd", "subnet-0030b35354cb9dad0", "subnet-0b2140cd594a4bccb"]
  provisioner_ip      = "10.0.0.99"
  route53_zone_id     = "Z06110132R7HO9BLI64XY"
  route53_zone_arn    = "arn:aws:route53::012345678910:hostedzone/${local.route53_zone_id}"
  acm_certificate_arn = "arn:aws:acm:us-east-1:012345678910:certificate/00000000-0000-0000-0000-000000000000"
  kms_key_arn         = "arn:aws:kms:us-east-1:012345678910:key/00000000-0000-0000-0000-000000000000"
  s3_bucket_id        = "datarobot-file-storage"

  tags = {
    application = local.name
    environment = "dev"
    managed-by  = "terraform"
  }
}

module "datarobot_infra" {
  source = "datarobot-oss/dr-infra/aws"

  name        = local.name
  domain_name = local.domain_name

  vpc_id                                    = local.vpc_id
  eks_subnet_ids                            = local.eks_subnet_ids
  route53_zone_id                           = local.route53_zone_id
  acm_certificate_arn                       = local.acm_certificate_arn
  kms_key_arn                               = local.kms_key_arn
  s3_bucket_id                              = local.s3_bucket_id
  create_eks_gpu_nodegroup                  = false
  eks_cluster_endpoint_public_access        = false
  eks_cluster_endpoint_private_access_cidrs = ["${local.provisioner_ip}/32"]

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
  source = "datarobot-oss/dr-infra/aws//modules/amenities"

  eks_cluster_name = module.datarobot_infra.eks_cluster_name
  vpc_id           = local.vpc_id

  install_cluster_autoscaler           = true
  install_ebs_csi_driver               = true
  ebs_csi_driver_kms_arn               = local.kms_key_arn
  install_aws_load_balancer_controller = true
  install_ingress_nginx                = true
  ingress_nginx_acm_certificate_arn    = local.acm_certificate_arn
  ingress_nginx_internet_facing        = false
  install_cert_manager                 = true
  cert_manager_hosted_zone_arns        = [local.route53_zone_arn]
  install_external_dns                 = true
  external_dns_hosted_zone_arn         = local.route53_zone_arn
  external_dns_hosted_zone_id          = local.route53_zone_id
  external_dns_hosted_zone_name        = local.domain_name

  tags = local.tags
}
