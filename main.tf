resource "aws_vpc" "this" {
  cidr_block           = var.vpc_cidr_block
  enable_dns_hostnames = true

  tags = var.tags
}

resource "aws_subnet" "kubernetes_nodes" {
  vpc_id     = aws_vpc.this.id
  cidr_block = var.kubernetes_nodes_cidr_block

  tags = var.tags
}

resource "aws_subnet" "kubernetes_ingress" {
  vpc_id     = aws_vpc.this.id
  cidr_block = var.kubernetes_ingress_cidr_block

  tags = merge(var.tags, { "kubernetes.io/role/elb" : "1" })
}

resource "aws_subnet" "kubernetes_controlplane" {
  vpc_id     = aws_vpc.this.id
  cidr_block = var.kubernetes_controlplane_cidr_block

  tags = var.tags
}

resource "aws_s3_bucket" "this" {
  bucket_prefix = replace(var.name, "_", "-")

  tags = var.tags
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.0"

  cluster_name    = var.name
  cluster_version = "1.30"

  cluster_endpoint_public_access = true

  cluster_addons = {
    coredns                = {}
    eks-pod-identity-agent = {}
    kube-proxy             = {}
    vpc-cni                = {}
  }

  enable_cluster_creator_admin_permissions = true

  vpc_id                   = aws_vpc.this.id
  subnet_ids               = [aws_subnet.kubernetes_nodes.id]
  control_plane_subnet_ids = [aws_subnet.kubernetes_controlplane.id]

  eks_managed_node_groups = {
    primary = {
      instance_types = ["r6i.4xlarge"]

      min_size     = 2
      max_size     = 6
      desired_size = 2
    }
  }

  tags = var.tags
}

module "app_role" {
  source = "terraform-aws-modules/iam/aws//modules/iam-assumable-role-with-oidc"

  create_role = true
  role_name   = "${var.name}-application"

  provider_url                 = replace(module.eks.cluster_oidc_issuer_url, "https://", "")
  oidc_subjects_with_wildcards = ["system:serviceaccount:${var.kubernetes_namespace}:*"]
  role_policy_arns = [
    "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryPowerUser",
    aws_iam_policy.s3_access_for_application.arn
  ]
  inline_policy_statements = [
    {
      sid = "AllowAccessToS3Bucket"
      actions = [
        "s3:DeleteObject",
        "s3:Get*",
        "s3:PutObject",
        "s3:ReplicateDelete",
        "s3:ListMultipartUploadParts"
      ]
      resources = [
        "arn:aws:s3:::${aws_s3_bucket.this.id}/*",
        "arn:aws:s3:::${aws_s3_bucket.this.id}"
      ]
    },
    {
      sid = "AllowListBuckets"
      actions = [
        "s3:ListBucket",
        "s3:ListBucketVersions",
        "s3:ListAllMyBuckets"
      ]
      resources = ["arn:aws:s3:::*"]
    }
  ]

  tags = var.tags
}
