resource "helm_release" "ingress_nginx" {
  name       = "ingress-nginx"
  namespace  = "ingress-nginx"
  repository = "https://kubernetes.github.io/ingress-nginx"
  chart      = "ingress-nginx"
  version    = "4.11.5"

  create_namespace = true

  values = [
    templatefile("${path.module}/common.yaml", {}),
    templatefile(var.internet_facing_ingress_lb ? "${path.module}/internet_facing.tftpl" : "${path.module}/internal.tftpl", {
      acm_certificate_arn = var.acm_certificate_arn,
      tags                = join(",", [for k, v in var.tags : "${k}=${v}"])
    }),
    var.custom_values_templatefile != "" ? templatefile(var.custom_values_templatefile, var.custom_values_variables) : ""
  ]
}

data "aws_lb" "internal_ingress" {
  depends_on = [helm_release.ingress_nginx]
  tags = {
    "elbv2.k8s.aws/cluster"    = var.eks_cluster_name
    "service.k8s.aws/resource" = "LoadBalancer"
    "service.k8s.aws/stack"    = "ingress-nginx/ingress-nginx-controller-internal"
  }
}

resource "aws_vpc_endpoint_service" "internal_ingress" {
  count = var.create_vpce_service && !var.internet_facing_ingress_lb ? 1 : 0

  acceptance_required        = false
  network_load_balancer_arns = [data.aws_lb.internal_ingress.arn]
  allowed_principals         = var.vpce_service_allowed_principals
  private_dns_name           = var.vpce_service_private_dns_name

  tags = merge(var.tags, { Name = "${var.eks_cluster_name}-ingress-vpce-service" })
}
