module "ebs_csi_driver_pod_identity" {
  source  = "terraform-aws-modules/eks-pod-identity/aws"
  version = "~> 1.0"

  name = "aws-ebs-csi"

  attach_aws_ebs_csi_policy = true
  aws_ebs_csi_kms_arns      = [var.aws_ebs_csi_kms_arn]

  associations = {
    this = {
      cluster_name    = var.eks_cluster_name
      namespace       = "kube-system"
      service_account = "ebs-csi-controller-sa"
    }
  }

  tags = var.tags
}


module "ebs_csi_driver" {
  source  = "terraform-module/release/helm"
  version = "2.8.1"

  namespace  = "kube-system"
  repository = "https://kubernetes-sigs.github.io/aws-ebs-csi-driver"

  app = {
    name             = "aws-ebs-csi-driver"
    version          = "2.33.0"
    chart            = "aws-ebs-csi-driver"
    create_namespace = true
    wait             = true
    recreate_pods    = false
    deploy           = 1
    timeout          = 600
  }

  values = [
    templatefile("${path.module}/values.yaml", {
      kms_key_arn = var.aws_ebs_csi_kms_arn
    }),
    var.custom_values_templatefile != "" ? templatefile(var.custom_values_templatefile, var.custom_values_variables) : ""
  ]
}
