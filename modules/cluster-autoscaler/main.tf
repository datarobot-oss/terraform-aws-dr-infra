data "aws_region" "current" {}

locals {
  name            = "cluster-autoscaler"
  namespace       = "cluster-autoscaler"
  service_account = "cluster-autoscaler-aws-cluster-autoscaler"
}

module "pod_identity" {
  source  = "terraform-aws-modules/eks-pod-identity/aws"
  version = "~> 2.0"

  name = local.name

  attach_cluster_autoscaler_policy = true
  cluster_autoscaler_cluster_names = [var.kubernetes_cluster_name]

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
  repository = "https://kubernetes.github.io/autoscaler"
  chart      = local.name
  version    = var.chart_version

  create_namespace = true

  values = [
    templatefile("${path.module}/values.yaml", {
      cluster_name = var.kubernetes_cluster_name,
      aws_region   = data.aws_region.current.region
    }),
    var.values_overrides
  ]

  depends_on = [module.pod_identity]
}
