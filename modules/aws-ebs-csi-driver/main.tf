module "aws_ebs_csi_driver_pod_identity" {
  source  = "terraform-aws-modules/eks-pod-identity/aws"
  version = "~> 1.0"

  name = "aws-ebs-csi"

  attach_aws_ebs_csi_policy = true
  aws_ebs_csi_kms_arns      = [var.aws_ebs_csi_kms_arn]

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
  version    = "2.37.0"

  create_namespace = true

  values = [
    templatefile("${path.module}/values.yaml", {
      encryption_key_id = var.aws_ebs_csi_kms_arn
    }),
    var.custom_values_templatefile != "" ? templatefile(var.custom_values_templatefile, var.custom_values_variables) : ""
  ]

  depends_on = [module.aws_ebs_csi_driver_pod_identity]
}
