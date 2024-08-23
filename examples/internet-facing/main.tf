provider "aws" {
  region = "us-west-2"
}

locals {
  name     = "datarobot"
  app_fqdn = "${local.name}.yourdomain.com"
  vpc_cidr = "10.7.0.0/16"
}

module "datarobot_infra" {
  source = "../.."

  name     = local.name
  app_fqdn = local.app_fqdn

  create_vpc               = true
  vpc_cidr                 = local.vpc_cidr
  create_dns_zone          = true
  create_acm_certificate   = true
  create_kms_key           = true
  create_s3_storage_bucket = true
  create_ecr_repositories  = true
  create_eks_cluster       = true
  eks_create_gpu_nodegroup = true
  create_app_irsa_role     = true

  aws_load_balancer_controller = true
  cert_manager                 = true
  cluster_autoscaler           = true
  ebs_csi_driver               = true
  external_dns                 = true
  ingress_nginx                = true
  internet_facing_ingress_lb   = true

  tags = {
    application = local.name
    environment = "dev"
    managed-by  = "terraform"
  }
}
