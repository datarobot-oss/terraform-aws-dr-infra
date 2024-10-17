
module "ingress_nginx" {
  source  = "terraform-module/release/helm"
  version = "~> 2.0"

  namespace  = "ingress-nginx"
  repository = "https://kubernetes.github.io/ingress-nginx"

  app = {
    name             = "ingress-nginx"
    version          = "4.11.1"
    chart            = "ingress-nginx"
    create_namespace = true
    wait             = true
    recreate_pods    = false
    deploy           = 1
    timeout          = 600
  }

  values = [
    templatefile("${path.module}/common.yaml", {}),
    templatefile(var.internet_facing_ingress_lb ? "${path.module}/internet_facing.tftpl" : "${path.module}/internal.tftpl", {
      acm_certificate_arn = var.acm_certificate_arn,
      tags                = join(",", [for k, v in var.tags : "${k}=${v}"])
    }),
    var.custom_values_templatefile != "" ? templatefile(var.custom_values_templatefile, var.custom_values_variables) : ""
  ]
}
