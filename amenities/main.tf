module "aws_loadbalancer_controller" {
  count  = var.aws_loadbalancer_controller ? 1 : 0
  source = "./aws-loadbalancer-controller"

  eks_cluster_name = var.eks_cluster_name
  vpc_id           = var.vpc_id

  custom_values_templatefile = var.aws_loadbalancer_controller_values
  custom_values_variables    = var.aws_loadbalancer_controller_variables

  tags = var.tags
}

module "cert_manager" {
  count  = var.cert_manager ? 1 : 0
  source = "./cert-manager"

  eks_cluster_name = var.eks_cluster_name
  route53_zone_arn = var.route53_zone_arn

  custom_values_templatefile = var.cert_manager_values
  custom_values_variables    = var.cert_manager_variables

  tags = var.tags
}

module "cluster_autoscaler" {
  count  = var.cluster_autoscaler ? 1 : 0
  source = "./cluster-autoscaler"

  eks_cluster_name = var.eks_cluster_name

  custom_values_templatefile = var.cluster_autoscaler_values
  custom_values_variables    = var.cluster_autoscaler_variables

  tags = var.tags
}

module "ebs_csi_driver" {
  count  = var.ebs_csi_driver ? 1 : 0
  source = "./ebs-csi-driver"

  eks_cluster_name     = var.eks_cluster_name
  aws_ebs_csi_kms_arns = []

  custom_values_templatefile = var.ebs_csi_driver_values
  custom_values_variables    = var.ebs_csi_driver_variables

  tags = var.tags
}

module "external_dns" {
  count  = var.external_dns ? 1 : 0
  source = "./external-dns"

  eks_cluster_name  = var.eks_cluster_name
  route53_zone_arn  = var.route53_zone_arn
  route53_zone_name = var.route53_zone_name

  custom_values_templatefile = var.external_dns_values
  custom_values_variables    = var.external_dns_variables

  tags = var.tags
}

module "ingress_nginx" {
  count  = var.ingress_nginx ? 1 : 0
  source = "./ingress-nginx"

  acm_certificate_arn = var.acm_certificate_arn
  app_hostname        = var.app_fqdn

  custom_values_templatefile = var.ingress_nginx_values
  custom_values_variables    = var.ingress_nginx_variables

  tags = var.tags
}
