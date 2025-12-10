locals {
  name      = "metrics-server"
  namespace = "metrics-server"
}

resource "helm_release" "this" {
  name       = local.name
  namespace  = local.namespace
  repository = "https://kubernetes-sigs.github.io/metrics-server"
  chart      = local.name
  version    = var.chart_version

  create_namespace = true

  values = [var.values_overrides]
}
