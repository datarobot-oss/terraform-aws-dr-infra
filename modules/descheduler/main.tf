locals {
  name      = "descheduler"
  namespace = "descheduler"
}

resource "helm_release" "this" {
  name       = local.name
  namespace  = local.namespace
  repository = "https://kubernetes-sigs.github.io/descheduler"
  chart      = "descheduler"
  version    = "0.33.0"

  create_namespace = true

  values = [
    file("${path.module}/values.yaml"),
    var.values_overrides
  ]
}
