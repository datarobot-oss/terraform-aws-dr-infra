module "cert_manager_pod_identity" {
  source = "terraform-aws-modules/eks-pod-identity/aws"

  name = "cert-manager"

  attach_cert_manager_policy    = true
  cert_manager_hosted_zone_arns = [var.route53_zone_arn]

  association_defaults = {
    cluster_name    = var.eks_cluster_name
    namespace       = "cert-manager"
    service_account = "cert-manager"
  }

  tags = var.tags
}

module "cert_manager" {
  source  = "terraform-module/release/helm"
  version = "~> 2.0"

  namespace  = "cert-manager"
  repository = "https://charts.jetstack.io"

  app = {
    name             = "cert-manager"
    version          = "1.15.2"
    chart            = "cert-manager"
    create_namespace = true
    wait             = true
    recreate_pods    = false
    deploy           = 1
    timeout          = 600
  }

  set = [
    {
      name  = "crds.enabled"
      value = "true"
    }
  ]
}
