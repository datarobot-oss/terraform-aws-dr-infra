provider "aws" {}

locals {
  name = "datarobot-infra-full-public"
}

module "datarobot-infra" {
  source = "../.."

  name                 = local.name
  app_fqdn             = "${local.name}.rd.int.datarobot.com"
  public               = true
  vpc_cidr             = "10.0.0.0/16"
  kubernetes_namespace = "dr-core"

  create_vpc               = true
  create_dns_zone          = true
  create_acm_certificate   = true
  create_s3_storage_bucket = true
  create_ecr_repositories  = true
  create_eks_cluster       = true
  create_app_irsa_role     = true

  aws_load_balancer_controller = true
  cert_manager                 = true
  cluster_autoscaler           = true
  ebs_csi_driver               = true
  external_dns                 = true
  ingress_nginx                = true

  tags = {
    datarobot-app = local.name
    managed-by    = "terraform"
  }
}
