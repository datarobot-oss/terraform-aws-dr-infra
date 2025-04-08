data "aws_region" "current" {}

module "cluster_autoscaler_pod_identity" {
  source  = "terraform-aws-modules/eks-pod-identity/aws"
  version = "~> 1.0"

  name = "cluster-autoscaler"

  attach_cluster_autoscaler_policy = true
  cluster_autoscaler_cluster_names = [var.kubernetes_cluster_name]

  associations = {
    this = {
      cluster_name    = var.kubernetes_cluster_name
      namespace       = "cluster-autoscaler"
      service_account = "cluster-autoscaler-aws-cluster-autoscaler"
    }
  }

  tags = var.tags
}

resource "helm_release" "cluster_autoscaler" {
  name       = "cluster-autoscaler"
  namespace  = "cluster-autoscaler"
  repository = "https://kubernetes.github.io/autoscaler"
  chart      = "cluster-autoscaler"
  version    = "9.43.2"

  create_namespace = true

  values = [
    templatefile("${path.module}/values.yaml", {}),
    var.custom_values_templatefile != "" ? templatefile(var.custom_values_templatefile, var.custom_values_variables) : ""
  ]

  set {
    name  = "autoDiscovery.clusterName"
    value = var.kubernetes_cluster_name
  }
  set {
    name  = "awsRegion"
    value = data.aws_region.current.name
  }

  depends_on = [module.cluster_autoscaler_pod_identity]
}
