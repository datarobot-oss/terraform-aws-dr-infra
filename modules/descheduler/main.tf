module "descheduler" {
  source  = "terraform-module/release/helm"
  version = "~> 2.0"

  namespace  = "descheduler"
  repository = "https://kubernetes-sigs.github.io/descheduler/"

  app = {
    name             = "descheduler"
    version          = "0.31.0"
    chart            = "descheduler"
    create_namespace = true
    wait             = true
    recreate_pods    = false
    deploy           = 1
    timeout          = 600
  }

  set = [
    {
      name  = "deschedulerPolicy.evictLocalStoragePods"
      value = "true"
    }
  ]

  values = [
    var.custom_values_templatefile != "" ? templatefile(var.custom_values_templatefile, var.custom_values_variables) : ""
  ]
}
