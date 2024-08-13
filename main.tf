provider "aws" {}

data "aws_availability_zones" "available" {}

locals {
  azs = slice(data.aws_availability_zones.available.names, 0, 3)
  ecr_repos = toset([
    "base-image",
    "ephemeral-image",
    "managed-image",
    "custom-apps-managed-image"
  ])
  hosted_zone_name = "${var.name}.${var.dns_zone}"
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  name = var.name
  cidr = var.vpc_cidr

  azs             = local.azs
  private_subnets = [for k, v in local.azs : cidrsubnet(var.vpc_cidr, 4, k)]
  public_subnets  = [for k, v in local.azs : cidrsubnet(var.vpc_cidr, 8, k + 48)]

  enable_nat_gateway = true
  single_nat_gateway = true

  public_subnet_tags = {
    "kubernetes.io/role/elb" = 1
  }
  private_subnet_tags = {
    "kubernetes.io/role/internal-elb" = 1
  }

  tags = var.tags
}

module "dns" {
  source  = "terraform-aws-modules/route53/aws//modules/zones"
  version = "~> 3.0"

  zones = {
    local.hosted_zone_name = {}
  }

  tags = var.tags
}

module "storage" {
  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "~> 4.0"

  bucket_prefix = replace(var.name, "_", "-")
  force_destroy = true
  #   acl           = "private"

  tags = var.tags
}

module "ecr" {
  source  = "terraform-aws-modules/ecr/aws"
  version = "~> 2.0"

  for_each = local.ecr_repos

  repository_name               = "${var.name}/${each.key}"
  repository_image_scan_on_push = false
  repository_force_delete       = true

  tags = var.tags
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.0"

  cluster_name    = var.name
  cluster_version = "1.30"

  cluster_endpoint_public_access = true

  cluster_addons = {
    coredns = {}
    # eks-pod-identity-agent = {}
    kube-proxy = {}
    vpc-cni    = {}
  }

  enable_cluster_creator_admin_permissions = true

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

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


module "app_irsa_role" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-assumable-role-with-oidc"
  version = "~> 5.0"

  create_role = true
  role_name   = "${var.name}-irsa"

  provider_url                 = replace(module.eks.cluster_oidc_issuer_url, "https://", "")
  oidc_subjects_with_wildcards = ["system:serviceaccount:${var.kubernetes_namespace}:*"]

  role_policy_arns = [
    "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryPowerUser"
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
        "arn:aws:s3:::${module.storage.s3_bucket_id}/*",
        "arn:aws:s3:::${module.storage.s3_bucket_id}"
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

module "ingress_nginx" {
  source  = "terraform-module/release/helm"
  version = "~> 2.0"

  namespace  = "ingress-nginx"
  repository = "https://kubernetes.github.io/ingress-nginx"

  app = {
    name             = "ingress-nginx"
    version          = "4.11.1"
    chart            = "ingress-nginx"
    create_namespace = true
    wait             = true
    recreate_pods    = false
    deploy           = 1
    timeout          = 600
  }
}

module "external_dns_pod_identity" {
  source = "terraform-aws-modules/eks-pod-identity/aws"

  name = "external-dns"

  attach_external_dns_policy    = true
  external_dns_hosted_zone_arns = [module.dns.route53_zone_zone_arn]

  association_defaults = {
    cluster_name    = module.eks.cluster_name
    namespace       = "external-dns"
    service_account = "external-dns"
  }

  tags = var.tags
}

module "external_dns" {
  source  = "terraform-module/release/helm"
  version = "~> 2.0"

  namespace  = "external-dns"
  repository = "https://charts.bitnami.com/bitnami"

  app = {
    name             = "external-dns"
    version          = "8.3.5"
    chart            = "external-dns"
    create_namespace = true
    wait             = true
    recreate_pods    = false
    deploy           = 1
    timeout          = 600
  }

  values = [
    templatefile(
      "${path.module}/templates/external_dns.tftpl",
      {
        clusterName           = module.eks.cluster_name,
        route53HostedZoneName = local.hosted_zone_name
      }
    )
  ]
}

module "cert_manager_pod_identity" {
  source = "terraform-aws-modules/eks-pod-identity/aws"

  name = "cert-manager"

  attach_cert_manager_policy    = true
  cert_manager_hosted_zone_arns = [module.dns.route53_zone_zone_arn]

  association_defaults = {
    cluster_name    = module.eks.cluster_name
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
}

module "cluster_autoscaler_pod_identity" {
  source = "terraform-aws-modules/eks-pod-identity/aws"

  name = "cluster-autoscaler"

  attach_cluster_autoscaler_policy = true
  cluster_autoscaler_cluster_names = [module.eks.cluster_name]

  association_defaults = {
    cluster_name    = module.eks.cluster_name
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
    version          = "1.30.2"
    chart            = "cluster-autoscaler"
    create_namespace = true
    wait             = true
    recreate_pods    = false
    deploy           = 1
    timeout          = 600
  }


}
