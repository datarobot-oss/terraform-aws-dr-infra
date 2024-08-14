module "cluster_autoscaler_pod_identity" {
  source = "terraform-aws-modules/eks-pod-identity/aws"

  name = "cluster-autoscaler"

  attach_cluster_autoscaler_policy = true
  cluster_autoscaler_cluster_names = [var.eks_cluster_name]

  association_defaults = {
    cluster_name    = var.eks_cluster_name
    namespace       = "kube-system"
    service_account = "cluster-autoscaler"
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

}
