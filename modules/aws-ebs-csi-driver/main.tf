locals {
  name            = "aws-ebs-csi-driver"
  namespace       = "aws-ebs-csi-driver"
  service_account = "ebs-csi-controller-sa"
}

module "pod_identity" {
  source  = "terraform-aws-modules/eks-pod-identity/aws"
  version = "~> 2.0"

  name = local.name

  attach_aws_ebs_csi_policy = true

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
  repository = "https://kubernetes-sigs.github.io/aws-ebs-csi-driver"
  chart      = local.name
  version    = "2.49.0"

  create_namespace = true

  values = [
    file("${path.module}/values.yaml"),
    var.values_overrides
  ]

  depends_on = [module.pod_identity]
}
