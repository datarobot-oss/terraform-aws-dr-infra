locals {
  name      = "gpu-operator"
  namespace = "gpu-operator"
}

resource "helm_release" "this" {
  name       = local.name
  namespace  = local.namespace
  repository = "https://helm.ngc.nvidia.com/nvidia"
  chart      = "gpu-operator"
  version    = "v25.3.0"

  create_namespace = true

  values = [
    file("${path.module}/values.yaml"),
    var.values_overrides
  ]
}
