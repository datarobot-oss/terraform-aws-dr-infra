resource "helm_release" "metrics_server" {
  name       = "metrics-server"
  namespace  = "metrics-server"
  repository = "https://kubernetes-sigs.github.io/metrics-server"
  chart      = "metrics-server"
  version    = "3.13.0"

  create_namespace = true

  values = [
    var.custom_values_templatefile != "" ? templatefile(var.custom_values_templatefile, var.custom_values_variables) : ""
  ]
}
