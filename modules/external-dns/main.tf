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

module "external_dns" {
  source  = "terraform-module/release/helm"
  version = "~> 2.0"

  namespace  = "external-dns"
  repository = "https://charts.bitnami.com/bitnami"

  app = {
    name             = "external-dns"
    version          = "8.5.1"
    chart            = "external-dns"
    create_namespace = true
    wait             = true
    recreate_pods    = false
    deploy           = 1
    timeout          = 600
  }

  values = [
    templatefile("${path.module}/values.tftpl", {
      domain      = var.route53_zone_name,
      clusterName = var.kubernetes_cluster_name
    }),
    var.custom_values_templatefile != "" ? templatefile(var.custom_values_templatefile, var.custom_values_variables) : ""
  ]

  depends_on = [module.external_dns_pod_identity]
}
