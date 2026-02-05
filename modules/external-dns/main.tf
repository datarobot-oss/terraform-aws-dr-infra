data "aws_route53_zone" "this" {
  zone_id = var.route53_zone_id
}

locals {
  name            = "external-dns"
  namespace       = "external-dns"
  service_account = "external-dns"
}

module "pod_identity" {
  source  = "terraform-aws-modules/eks-pod-identity/aws"
  version = "~> 2.0"

  name = local.name

  attach_external_dns_policy    = true
  external_dns_hosted_zone_arns = [data.aws_route53_zone.this.arn]

  associations = {
    this = {
      cluster_name    = var.kubernetes_cluster_name
      namespace       = local.namespace
      service_account = local.service_account
    }
  }

  tags = var.tags
}

resource "helm_release" "this" {
  name       = local.name
  namespace  = local.namespace
  repository = "https://kubernetes-sigs.github.io/external-dns"
  chart      = local.name
  version    = var.chart_version

  create_namespace = true

  values = [
    templatefile("${path.module}/values.yaml", {
      domain      = data.aws_route53_zone.this.name,
      zone_id     = var.route53_zone_id,
      clusterName = var.kubernetes_cluster_name
    }),
    var.values_overrides
  ]

  depends_on = [module.pod_identity]
}
