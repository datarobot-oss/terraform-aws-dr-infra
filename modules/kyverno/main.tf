locals {
  name      = "kyverno"
  namespace = "kyverno"
}

resource "helm_release" "this" {
  name       = local.name
  namespace  = local.namespace
  repository = "https://kyverno.github.io/kyverno"
  chart      = local.name
  version    = var.chart_version

  create_namespace = true

  values = [
    file("${path.module}/values.yaml"),
    var.values_overrides
  ]
}

resource "helm_release" "policies" {
  count = var.install_policies ? 1 : 0

  name       = "kyverno-policies"
  namespace  = local.namespace
  repository = "https://kyverno.github.io/kyverno"
  chart      = "kyverno-policies"
  version    = var.policies_chart_version

  values = [var.policies_values_overrides]

  depends_on = [helm_release.this]
}

module "notation_aws_pod_identity" {
  source = "terraform-aws-modules/eks-pod-identity/aws"

  name = "kyverno-notation-aws"

  attach_custom_policy = true
  policy_statements = [
    {
      effect = "Allow"
      actions = [
        "signer:GetRevocationStatus"
      ]
      resources = ["*"]
    }
  ]

  associations = {
    this = {
      cluster_name    = var.eks_cluster_name
      namespace       = local.namespace
      service_account = "kyverno-notation-aws"
    }
  }
}

resource "helm_release" "notation_aws" {
  count = var.notation_aws ? 1 : 0

  name       = "kyverno-notation-aws"
  namespace  = local.namespace
  repository = "oci://ghcr.io/nirmata/charts"
  chart      = "kyverno-notation-aws"
  version    = var.notation_aws_chart_version

  values = [var.notation_aws_values_overrides]

  depends_on = [helm_release.this, module.notation_aws_pod_identity]
}

resource "kubectl_manifest" "aws_signer_trust_store" {
  count = var.notation_aws ? 1 : 0

  yaml_body = <<YAML
apiVersion: notation.nirmata.io/v1alpha1
kind: TrustStore
metadata:
  name: aws-signer-ts
spec:
  trustStoreName: aws-signer-ts
  type: signingAuthority
  # The AWS root cert for commercial regions can be downloaded from:
  #   https://d2hvyiie56hcat.cloudfront.net/aws-signer-notation-root.cert
  caBundle: |-
    -----BEGIN CERTIFICATE-----
    MIICWTCCAd6gAwIBAgIRAMq5Lmt4rqnUdi8qM4eIGbYwCgYIKoZIzj0EAwMwbDEL
    MAkGA1UEBhMCVVMxDDAKBgNVBAoMA0FXUzEVMBMGA1UECwwMQ3J5cHRvZ3JhcGh5
    MQswCQYDVQQIDAJXQTErMCkGA1UEAwwiQVdTIFNpZ25lciBDb2RlIFNpZ25pbmcg
    Um9vdCBDQSBHMTAgFw0yMjEwMjcyMTMzMjJaGA8yMTIyMTAyNzIyMzMyMlowbDEL
    MAkGA1UEBhMCVVMxDDAKBgNVBAoMA0FXUzEVMBMGA1UECwwMQ3J5cHRvZ3JhcGh5
    MQswCQYDVQQIDAJXQTErMCkGA1UEAwwiQVdTIFNpZ25lciBDb2RlIFNpZ25pbmcg
    Um9vdCBDQSBHMTB2MBAGByqGSM49AgEGBSuBBAAiA2IABM9+dM9WXbVyNOIP08oN
    IQW8DKKdBxP5nYNegFPLfGP0f7+0jweP8LUv1vlFZqVDep5ONus9IxwtIYBJLd36
    5Q3Z44Xnm4PY/wSI5xRvB/m+/B2PHc7Smh0P5s3Dt25oVKNCMEAwDwYDVR0TAQH/
    BAUwAwEB/zAdBgNVHQ4EFgQUONhd3abPX87l4YWKxjysv28QwAYwDgYDVR0PAQH/
    BAQDAgGGMAoGCCqGSM49BAMDA2kAMGYCMQCd32GnYU2qFCtKjZiveGfs+gCBlPi2
    Hw0zU52LXIFC2GlcvwcekbiM6w0Azlr9qvMCMQDl4+Os0yd+fVlYMuovvxh8xpjQ
    NPJ9zRGyYa7+GNs64ty/Z6bzPHOKbGo4In3KKJo=
    -----END CERTIFICATE-----
YAML

  depends_on = [helm_release.notation_aws]
}

resource "kubectl_manifest" "aws_signer_trust_policy" {
  count = var.notation_aws ? 1 : 0

  yaml_body = <<YAML
apiVersion: notation.nirmata.io/v1alpha1
kind: TrustPolicy
metadata:
  name: aws-signer-trust-policy
spec:
  version: '1.0'
  trustPolicyName: aws-signer-trust-policy
  trustPolicies:
  - name: aws-signer-tp
    registryScopes:
    - "*"
    signatureVerification:
      level: strict
      override: {}
    trustStores:
    - signingAuthority:aws-signer-ts
    trustedIdentities:
    - ${var.signer_profile_arn}
  YAML

  depends_on = [helm_release.notation_aws]
}

resource "kubectl_manifest" "check_images_policy" {
  count = var.notation_aws ? 1 : 0

  yaml_body = <<YAML
apiVersion: kyverno.io/v1
kind: ClusterPolicy
metadata:
  name: check-images
spec:
  validationFailureAction: Enforce
  failurePolicy: Fail
  webhookTimeoutSeconds: 30
  schemaValidation: false
  rules:
  - name: call-aws-signer-extension
    match:
      any:
      - resources:
          kinds:
          - Pod
          operations:
            - CREATE
            - UPDATE
    context:
    - name: tlscerts
      apiCall:
        urlPath: "/api/v1/namespaces/kyverno/secrets/kyverno-notation-aws-svc.kyverno.svc.tls-pair"
        jmesPath: "base64_decode( data.\"tls.crt\" )"
    - name: response
      apiCall:
        method: POST
        data:
        - key: images
          value: "{{images}}"
        service:
          url: "https://kyverno-notation-aws-svc/checkimages"
          caBundle: '{{ tlscerts }}'
    mutate:
      foreach:
      - list: "response.results"
        patchesJson6902: |-
            - path: '{{ element.path }}'
              op: '{{ element.op }}'
              value: '{{ element.value }}'
YAML

  depends_on = [kubectl_manifest.aws_signer_trust_policy]
}
