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
  create_kms_key           = true
  create_s3_storage_bucket = true
  create_ecr_repositories  = true
  create_eks_cluster       = true
  eks_create_gpu_nodegroup = false
  create_app_irsa_role     = true

  aws_load_balancer_controller = true
  cert_manager                 = true
  cluster_autoscaler           = true
  ebs_csi_driver               = true
  external_dns                 = true
  ingress_nginx                = true
  internet_facing_ingress_lb   = false

  tags = {
    application = local.name
    environment = "dev"
    managed-by  = "terraform"
  }
}
