locals {
  name      = "cilium"
  namespace = "kube-system"
}

resource "helm_release" "this" {
  name       = local.name
  namespace  = local.namespace
  repository = "https://helm.cilium.io"
  chart      = local.name
  version    = var.chart_version

  create_namespace = true

  values = [
    file("${path.module}/values.yaml"),
    var.values_overrides
  ]
}
