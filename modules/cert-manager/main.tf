locals {
  name            = "cert-manager"
  namespace       = "cert-manager"
  service_account = "cert-manager"
}

module "pod_identity" {
  source  = "terraform-aws-modules/eks-pod-identity/aws"
  version = "~> 2.0"

  name = local.name

  attach_cert_manager_policy    = true
  cert_manager_hosted_zone_arns = [var.route53_zone_arn]

  associations = {
    this = {
      cluster_name    = var.kubernetes_cluster_name
      namespace       = local.namespace
      service_account = local.service_account
    }
  }

  tags = var.tags
}

resource "helm_release" "this" {
  name       = local.name
  namespace  = local.namespace
  repository = "https://charts.jetstack.io"
  chart      = local.name
  version    = var.chart_version

  create_namespace = true

  values = [
    file("${path.module}/values.yaml"),
    var.values_overrides
  ]

  depends_on = [module.pod_identity]
}
