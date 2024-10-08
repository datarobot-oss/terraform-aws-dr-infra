provider "aws" {
  region = "us-west-2"
}

locals {
  name        = "datarobot"
  domain_name = "${local.name}.yourdomain.com"
  vpc_cidr    = "10.7.0.0/16"
}

module "datarobot_infra" {
  source = "datarobot-oss/dr-infra/aws"

  name        = local.name
  domain_name = local.domain_name

  create_vpc               = true
  vpc_cidr                 = local.vpc_cidr
  create_dns_zone          = true
  create_acm_certificate   = true
  create_kms_key           = true
  create_s3_bucket         = true
  create_ecr_repositories  = true
  create_eks_cluster       = true
  create_eks_gpu_nodegroup = true
  create_app_irsa_role     = true

  aws_load_balancer_controller = true
  cert_manager                 = true
  cluster_autoscaler           = true
  ebs_csi_driver               = true
  external_dns                 = true
  ingress_nginx                = true
  internet_facing_ingress_lb   = true
  nvidia_device_plugin         = true

  tags = {
    application = local.name
    environment = "dev"
    managed-by  = "terraform"
  }
}
