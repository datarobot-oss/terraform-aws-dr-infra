module "external_dns_pod_identity" {
  source  = "terraform-aws-modules/eks-pod-identity/aws"
  version = "~> 2.0"

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
  repository = "https://kubernetes-sigs.github.io/external-dns"
  chart      = "external-dns"
  version    = "1.19.0"

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
