resource "helm_release" "metrics_server" {
  name       = "metrics-server"
  namespace  = "metrics-server"
  repository = "https://kubernetes-sigs.github.io/metrics-server"
  chart      = "metrics-server"
  version    = "v3.12.1"

  create_namespace = true

  values = [
    var.custom_values_templatefile != "" ? templatefile(var.custom_values_templatefile, var.custom_values_variables) : ""
  ]
}
