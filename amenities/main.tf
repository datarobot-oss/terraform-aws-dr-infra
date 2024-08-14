module "cert_manager" {
  count = var.cert_manager ? 1 : 0
  source = "./cert-manager"

  eks_cluster_name = var.eks_cluster_name
  route53_zone_arn = var.route53_zone_arn

  tags = var.tags
}

module "cluster_autoscaler" {
  count = var.cluster_autoscaler ? 1 : 0
  source = "./cluster-autoscaler"

  eks_cluster_name = var.eks_cluster_name

  tags = var.tags
}

module "external_dns" {
  count = var.external_dns ? 1 : 0
  source = "./external-dns"

  eks_cluster_name = var.eks_cluster_name
  route53_zone_arn = var.route53_zone_arn
  route53_zone_name = var.route53_zone_name

  tags = var.tags
}

module "ingress_nginx" {
  count = var.ingress_nginx ? 1 : 0
  source = "./ingress-nginx"

  acm_certificate_arn = var.acm_certificate_arn
}
