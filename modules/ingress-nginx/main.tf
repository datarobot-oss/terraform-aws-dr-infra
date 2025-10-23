locals {
  name      = "ingress-nginx"
  namespace = "ingress-nginx"
}

resource "helm_release" "this" {
  name       = local.name
  namespace  = local.namespace
  repository = "https://kubernetes.github.io/ingress-nginx"
  chart      = "ingress-nginx"
  version    = "4.13.2"

  create_namespace = true

  values = [
    templatefile("${path.module}/values.yaml", {
      load_balancer_scheme = var.internet_facing_ingress_lb ? "internet-facing" : "internal"
      tags                 = join(",", [for k, v in var.tags : "${k}=${v}"])
    }),
    var.values_overrides
  ]

  set = var.acm_certificate_arn != null ? [
    {
      name  = "controller.service.annotations.service\\.beta\\.kubernetes\\.io/aws-load-balancer-ssl-cert"
      value = var.acm_certificate_arn
    },
    {
      name  = "controller.service.targetPorts.https"
      value = "http"
    }
  ] : []
}

data "aws_lb" "ingress" {
  count      = var.internet_facing_ingress_lb ? 0 : 1
  depends_on = [helm_release.this]

  tags = {
    "elbv2.k8s.aws/cluster"    = var.eks_cluster_name
    "service.k8s.aws/resource" = "LoadBalancer"
    "service.k8s.aws/stack"    = "ingress-nginx/ingress-nginx-controller"
  }
}

resource "aws_vpc_endpoint_service" "ingress" {
  count = var.create_vpce_service && !var.internet_facing_ingress_lb ? 1 : 0

  acceptance_required        = false
  network_load_balancer_arns = [data.aws_lb.ingress[0].arn]
  allowed_principals         = var.vpce_service_allowed_principals
  private_dns_name           = var.vpce_service_private_dns_name

  tags = merge(var.tags, { Name = "${var.eks_cluster_name}-ingress-vpce-service" })
}
