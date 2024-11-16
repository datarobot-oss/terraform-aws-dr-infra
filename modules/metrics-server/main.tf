module "metrics_server" {
  source  = "terraform-module/release/helm"
  version = "~> 2.0"

  namespace  = "metrics-server"
  repository = "https://kubernetes-sigs.github.io/metrics-server/"

  app = {
    name             = "metrics-server"
    version          = "v3.12.1"
    chart            = "metrics-server"
    create_namespace = true
    wait             = true
    recreate_pods    = false
    deploy           = 1
    timeout          = 600
  }

  values = [
    var.custom_values_templatefile != "" ? templatefile(var.custom_values_templatefile, var.custom_values_variables) : ""
  ]

}
