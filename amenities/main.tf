module "aws_loadbalancer_controller" {
  count  = var.aws_loadbalancer_controller ? 1 : 0
  source = "./aws-loadbalancer-controller"

  eks_cluster_name = var.eks_cluster_name
  vpc_id           = var.vpc_id

  tags = var.tags
}

module "cert_manager" {
  count  = var.cert_manager ? 1 : 0
  source = "./cert-manager"

  eks_cluster_name = var.eks_cluster_name
  route53_zone_arn = var.route53_zone_arn

  tags = var.tags
}

module "cluster_autoscaler" {
  count  = var.cluster_autoscaler ? 1 : 0
  source = "./cluster-autoscaler"

  eks_cluster_name = var.eks_cluster_name

  tags = var.tags
}

module "ebs_csi_driver" {
  count  = var.ebs_csi_driver ? 1 : 0
  source = "./ebs-csi-driver"

  eks_cluster_name     = var.eks_cluster_name
  aws_ebs_csi_kms_arns = []

  tags = var.tags
}

module "external_dns" {
  count  = var.external_dns ? 1 : 0
  source = "./external-dns"

  eks_cluster_name  = var.eks_cluster_name
  route53_zone_arn  = var.route53_zone_arn
  route53_zone_name = var.route53_zone_name

  tags = var.tags
}

module "ingress_nginx" {
  count  = var.ingress_nginx ? 1 : 0
  source = "./ingress-nginx"

  acm_certificate_arn = var.acm_certificate_arn
  app_hostname        = var.app_fqdn
}
