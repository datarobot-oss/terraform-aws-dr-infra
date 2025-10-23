locals {
  name      = "metrics-server"
  namespace = "metrics-server"
}

resource "helm_release" "this" {
  name       = local.name
  namespace  = local.namespace
  repository = "https://kubernetes-sigs.github.io/metrics-server"
  chart      = "metrics-server"
  version    = "3.13.0"

  create_namespace = true

  values = [var.values_overrides]
}
