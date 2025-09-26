module "aws_ebs_csi_driver_pod_identity" {
  source  = "terraform-aws-modules/eks-pod-identity/aws"
  version = "~> 2.0"

  name = "aws-ebs-csi"

  attach_aws_ebs_csi_policy = true

  associations = {
    this = {
      cluster_name    = var.kubernetes_cluster_name
      namespace       = "aws-ebs-csi-driver"
      service_account = "ebs-csi-controller-sa"
    }
  }

  tags = var.tags
}

resource "helm_release" "aws_ebs_csi_driver" {
  name       = "aws-ebs-csi-driver"
  namespace  = "aws-ebs-csi-driver"
  repository = "https://kubernetes-sigs.github.io/aws-ebs-csi-driver"
  chart      = "aws-ebs-csi-driver"
  version    = "2.49.0"

  create_namespace = true

  values = [
    templatefile("${path.module}/values.yaml", {}),
    var.custom_values_templatefile != "" ? templatefile(var.custom_values_templatefile, var.custom_values_variables) : ""
  ]

  depends_on = [module.aws_ebs_csi_driver_pod_identity]
}
