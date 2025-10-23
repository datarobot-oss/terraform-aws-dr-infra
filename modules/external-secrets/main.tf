locals {
  name            = "external-secrets"
  namespace       = "external-secrets"
  service_account = "external-secrets"
}

module "pod_identity" {
  source  = "terraform-aws-modules/eks-pod-identity/aws"
  version = "~> 2.0"

  name = local.name

  attach_external_secrets_policy        = true
  external_secrets_secrets_manager_arns = var.secrets_manager_arns

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
  repository = "https://charts.external-secrets.io"
  chart      = "external-secrets"
  version    = "0.16.2"

  create_namespace = true

  values = [var.values_overrides]

  depends_on = [module.pod_identity]
}
