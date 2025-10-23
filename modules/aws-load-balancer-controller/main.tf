locals {
  name            = "aws-load-balancer-controller"
  namespace       = "aws-load-balancer-controller"
  service_account = "aws-load-balancer-controller"
}

module "pod_identity" {
  source  = "terraform-aws-modules/eks-pod-identity/aws"
  version = "~> 2.0"

  name = local.name

  attach_aws_lb_controller_policy = true

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
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"
  version    = "1.13.4"

  create_namespace = true

  values = [
    templatefile("${path.module}/values.yaml", {
      cluster_name = var.kubernetes_cluster_name
      vpc_id       = var.vpc_id
    }),
    var.values_overrides
  ]

  depends_on = [module.pod_identity]
}
