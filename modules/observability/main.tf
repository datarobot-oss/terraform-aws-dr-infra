data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

locals {
  name = "${var.name}-observability"
}

resource "aws_prometheus_workspace" "observability_prom_workspace" {
  alias = "${local.name}-prometheus"
  tags  = var.tags
}

data "aws_iam_policy_document" "observability_write_document" {
  # Policy document to allow writing to CloudWatch logs, X-Ray traces, and Prometheus
  statement {
    sid    = "AllowCloudWatchLogs"
    effect = "Allow"
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
      "logs:DescribeLogStreams"
    ]
    resources = ["arn:aws:logs:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:log-group:*:log-stream:*"]
  }

  statement {
    sid    = "AllowXRayTracing"
    effect = "Allow"
    actions = [
      "xray:PutTraceSegments",
      "xray:PutTelemetryRecords",
    ]
    # AWS: This action does not support resource-level permissions.
    # Policies granting access must specify "*" in the resource element.
    resources = ["*"]
  }

  statement {
    sid       = "AllowPrometheusRemoteWrite"
    effect    = "Allow"
    actions   = ["aps:RemoteWrite"]
    resources = [aws_prometheus_workspace.observability_prom_workspace.arn]
  }
}

resource "aws_iam_policy" "observability_policy" {
  name        = "${local.name}-cloudwatch-prometheus-write-policy"
  path        = "/"
  description = "IAM policy for Observability for CloudWatch (logs and traces)"
  policy      = data.aws_iam_policy_document.observability_write_document.json
  tags        = var.tags
}

resource "aws_iam_role_policy_attachment" "observability_policy_attachment" {
  role       = var.kubernetes_iam_role_name
  policy_arn = aws_iam_policy.observability_policy.arn
}

# It's more convenient to use a custom role instead of an AWS managed one since the permissions
# for the Prometheus workspace can already be set.
resource "aws_iam_role" "observability_amp_query_role" {
  name               = "${local.name}-grafana-role"
  description        = "IAM role for Amazon Managed Grafana to read metrics from Amazon Managed Prometheus."
  assume_role_policy = data.aws_iam_policy_document.observability_grafana_amp_trust_policy.json
  tags               = var.tags
}

data "aws_iam_policy_document" "observability_grafana_amp_trust_policy" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["grafana.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [data.aws_caller_identity.current.account_id]
    }

    condition {
      test     = "StringLike"
      variable = "aws:SourceArn"
      values   = ["arn:aws:grafana:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:/workspaces/*"]
    }
  }
}

data "aws_iam_policy_document" "observability_amp_read_policy_document" {
  statement {
    effect = "Allow"
    actions = [
      "aps:ListWorkspaces",
      "aps:DescribeWorkspace",
      "aps:QueryMetrics",
      "aps:GetLabels",
      "aps:GetSeries",
      "aps:GetMetricMetadata",
    ]

    resources = [
      aws_prometheus_workspace.observability_prom_workspace.arn
    ]
  }
}

resource "aws_iam_policy" "observability_amp_read_policy" {
  name        = "${local.name}-prometheus-readonly-policy"
  path        = "/"
  description = "IAM policy for reading Prometheus workspace"
  policy      = data.aws_iam_policy_document.observability_amp_read_policy_document.json
  tags        = var.tags
}

resource "aws_iam_role_policy_attachment" "observability_amp_read_policy_attachment" {
  role       = aws_iam_role.observability_amp_query_role.arn
  policy_arn = aws_iam_policy.observability_amp_read_policy.arn
}

resource "aws_grafana_workspace" "grafana" {
  name                     = "${local.name}-grafana"
  account_access_type      = "CURRENT_ACCOUNT"
  authentication_providers = ["AWS_SSO"]
  permission_type          = "CUSTOMER_MANAGED"
  role_arn                 = aws_iam_role.observability_amp_query_role.arn
}
