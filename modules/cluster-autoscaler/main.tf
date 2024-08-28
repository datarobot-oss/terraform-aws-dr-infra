data "aws_region" "current" {}

module "cluster_autoscaler_pod_identity" {
  source  = "terraform-aws-modules/eks-pod-identity/aws"
  version = "~> 1.0"

  name = "cluster-autoscaler"

  attach_cluster_autoscaler_policy = true
  cluster_autoscaler_cluster_names = [var.eks_cluster_name]

  associations = {
    this = {
      cluster_name    = var.eks_cluster_name
      namespace       = "cluster-autoscaler"
      service_account = "cluster-autoscaler-aws-cluster-autoscaler"
    }
  }

  tags = var.tags
}

module "cluster_autoscaler" {
  source  = "terraform-module/release/helm"
  version = "~> 2.0"

  namespace  = "cluster-autoscaler"
  repository = "https://kubernetes.github.io/autoscaler"

  app = {
    name             = "cluster-autoscaler"
    version          = "9.37.0"
    chart            = "cluster-autoscaler"
    create_namespace = true
    wait             = true
    recreate_pods    = false
    deploy           = 1
    timeout          = 600
  }

  set = [
    {
      name  = "autoDiscovery.clusterName"
      value = var.eks_cluster_name
    },
    {
      name  = "awsRegion"
      value = data.aws_region.current.name
    }
  ]

  values = [
    var.custom_values_templatefile != "" ? templatefile(var.custom_values_templatefile, var.custom_values_variables) : ""
  ]

}
