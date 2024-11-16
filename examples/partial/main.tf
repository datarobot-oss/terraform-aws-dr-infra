provider "aws" {
  region = "us-west-2"
}

locals {
  name           = "datarobot"
  provisioner_ip = "10.0.0.99"
}

module "datarobot_infra" {
  source = "../.."

  name        = local.name
  domain_name = "${local.name}.yourdomain.com"

  existing_vpc_id                     = "vpc-1234556abcdef"
  existing_kubernetes_nodes_subnet_id = ["subnet-abcde012", "subnet-bcde012a", "subnet-fghi345a"]
  existing_private_route53_zone_id    = "Z06110132R7HO9BLI64XY"
  existing_acm_certificate_arn        = "arn:aws:acm:us-west-2:000000000000:certificate/00000000-0000-0000-0000-000000000000"
  existing_kms_key_arn                = "arn:aws:kms:us-west-2:500395161552:key/00000000-0000-0000-0000-000000000000"
  existing_s3_bucket_id               = "datarobot-file-storage-12345"

  # disable public internet access to the Kubernetes API endpoint
  kubernetes_cluster_endpoint_public_access = false

  # allow a specific host running within the same VPC to access the Kubernetes API endpoint
  kubernetes_cluster_endpoint_private_access_cidrs = ["${local.provisioner_ip}/32"]

  # create an internal LB for ingress rather than internet-facing
  internet_facing_ingress_lb = false

  tags = {
    application = local.name
    environment = "dev"
    managed-by  = "terraform"
  }
}
