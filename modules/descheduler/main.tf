resource "helm_release" "descheduler" {
  name       = "descheduler"
  namespace  = "descheduler"
  repository = "https://kubernetes-sigs.github.io/descheduler"
  chart      = "descheduler"
  version    = "0.31.0"

  create_namespace = true

  values = [
    var.custom_values_templatefile != "" ? templatefile(var.custom_values_templatefile, var.custom_values_variables) : ""
  ]

  set = [
    {
      name  = "deschedulerPolicy.evictLocalStoragePods"
      value = "true"
    }
  ]
}
