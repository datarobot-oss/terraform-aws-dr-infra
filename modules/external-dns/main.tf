module "external_dns_pod_identity" {
  source  = "terraform-aws-modules/eks-pod-identity/aws"
  version = "~> 1.0"

  name = "external-dns"

  attach_external_dns_policy    = true
  external_dns_hosted_zone_arns = [var.route53_zone_arn]

  associations = {
    this = {
      cluster_name    = var.kubernetes_cluster_name
      namespace       = "external-dns"
      service_account = "external-dns"
    }
  }

  tags = var.tags
}

resource "helm_release" "external_dns" {
  name       = "external-dns"
  namespace  = "external-dns"
  repository = "https://charts.bitnami.com/bitnami"
  chart      = "external-dns"
  version    = "8.5.1"

  create_namespace = true

  values = [
    templatefile("${path.module}/values.tftpl", {
      domain      = var.route53_zone_name,
      clusterName = var.kubernetes_cluster_name
    }),
    var.custom_values_templatefile != "" ? templatefile(var.custom_values_templatefile, var.custom_values_variables) : ""
  ]

  depends_on = [module.external_dns_pod_identity]
}
