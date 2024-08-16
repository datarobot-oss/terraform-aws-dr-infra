module "aws_loadbalancer_controller_pod_identity" {
  source = "terraform-aws-modules/eks-pod-identity/aws"

  name = "aws-lbc"

  attach_aws_lb_controller_policy = true

  associations = {
    this = {
      cluster_name    = var.eks_cluster_name
      namespace       = "aws-load-balancer-controller"
      service_account = "aws-load-balancer-controller"
    }
  }

  tags = var.tags
}

module "aws_loadbalancer_controller" {
  source  = "terraform-module/release/helm"
  version = "~> 2.0"

  namespace  = "aws-load-balancer-controller"
  repository = "https://aws.github.io/eks-charts"

  app = {
    name             = "aws-load-balancer-controller"
    version          = "1.8.2"
    chart            = "aws-load-balancer-controller"
    create_namespace = true
    wait             = true
    recreate_pods    = false
    deploy           = 1
    timeout          = 600
  }

  set = [
    {
      name  = "clusterName"
      value = var.eks_cluster_name
    },
    {
      name = "vpcId"
      value = var.vpc_id
    }
  ]
}
