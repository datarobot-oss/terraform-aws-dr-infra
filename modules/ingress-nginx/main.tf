resource "helm_release" "ingress_nginx" {
  name       = "ingress-nginx"
  namespace  = "ingress-nginx"
  repository = "https://kubernetes.github.io/ingress-nginx"
  chart      = "ingress-nginx"
  version    = "4.11.5"

  create_namespace = true

  values = [
    templatefile("${path.module}/common.yaml", {}),
    templatefile(var.internet_facing_ingress_lb ? "${path.module}/internet_facing.tftpl" : "${path.module}/internal.tftpl", {
      acm_certificate_arn = var.acm_certificate_arn,
      tags                = join(",", [for k, v in var.tags : "${k}=${v}"])
    }),
    var.custom_values_templatefile != "" ? templatefile(var.custom_values_templatefile, var.custom_values_variables) : ""
  ]
}
