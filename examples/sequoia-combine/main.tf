provider "aws" {
  region = var.region
}

data "aws_partition" "current" {}
data "aws_caller_identity" "current" {}
data "aws_iam_session_context" "current" {
  arn = data.aws_caller_identity.current.arn
}
data "aws_vpc" "this" {
  id = var.vpc_id
}

locals {
  iam_role_permissions_boundary_arn = "arn:${data.aws_partition.current.partition}:iam::${data.aws_caller_identity.current.account_id}:policy/${var.eks_iam_role_permissions_boundary_name}"
}

### SSH key pair for EKS nodes
resource "tls_private_key" "this" {
  algorithm = "RSA"
}

resource "local_sensitive_file" "ssh_key" {
  content  = tls_private_key.this.private_key_pem
  filename = "${path.module}/${var.name}.pem"
}

resource "aws_key_pair" "this" {
  key_name   = "${var.name}-node-ssh-key"
  public_key = tls_private_key.this.public_key_openssh
}

### EKS node IAM role
data "aws_iam_policy_document" "eks_node_assume_role_policy" {
  statement {
    sid     = "EKSNodeAssumeRole"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "eks_nodes" {
  name = var.eks_cluster_nodes_iam_role_name

  assume_role_policy    = data.aws_iam_policy_document.eks_node_assume_role_policy.json
  permissions_boundary  = local.iam_role_permissions_boundary_arn
  force_detach_policies = true

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "eks_nodes" {
  for_each = { for k, v in {
    AmazonEKSWorkerNodePolicy          = "arn:${data.aws_partition.current.partition}:iam::aws:policy/AmazonEKSWorkerNodePolicy"
    AmazonEC2ContainerRegistryReadOnly = "arn:${data.aws_partition.current.partition}:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
    AmazonEKS_CNI_Policy               = "arn:${data.aws_partition.current.partition}:iam::aws:policy/AmazonEKS_CNI_Policy"
  } : k => v }

  policy_arn = each.value
  role       = aws_iam_role.eks_nodes.name
}

### DataRobot infrastructure
module "datarobot_infra" {
  source = "../.."

  name = var.name

  existing_vpc_id                      = var.vpc_id
  existing_kubernetes_nodes_subnet_ids = var.private_subnet_ids

  kubernetes_cluster_version = var.eks_cluster_version

  kubernetes_enable_cluster_creator_admin_permissions = false
  kubernetes_cluster_access_entries = {
    cluster_admin = {
      principal_arn = data.aws_iam_session_context.current.issuer_arn
      policy_associations = {
        cluster_admin = {
          policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
          access_scope = {
            type = "cluster"
          }
        }
      }
    }
    nodes = {
      principal_arn = aws_iam_role.eks_nodes.arn
      type          = "EC2"
    }
  }

  kubernetes_cluster_endpoint_public_access        = false
  kubernetes_cluster_endpoint_private_access_cidrs = [data.aws_vpc.this.cidr_block]
  kubernetes_node_security_group_additional_rules = {
    bastion_ssh = {
      description = "SSH from bastion host"
      protocol    = "tcp"
      from_port   = 22
      to_port     = 22
      type        = "ingress"
      cidr_blocks = var.bastion_private_ip != null ? ["${var.bastion_private_ip}/32"] : []
    }
  }

  ### Combine-specific values related to IAM restrictions
  kubernetes_iam_role_name                 = var.eks_cluster_iam_role_name
  kubernetes_iam_role_use_name_prefix      = false
  kubernetes_iam_role_permissions_boundary = local.iam_role_permissions_boundary_arn
  kubernetes_enable_auto_mode_custom_tags  = false
  kubernetes_cluster_encryption_config     = {}
  kubernetes_enable_irsa                   = false
  kubernetes_cluster_addons                = {}
  kubernetes_node_group_defaults = {
    create_iam_role = false
    iam_role_arn    = aws_iam_role.eks_nodes.arn
    key_name        = aws_key_pair.this.key_name
    cloudinit_pre_nodeadm = [
      {
        # The InstanceIdNodeName nodeadm feature gate is used in Combine
        # so the node does not have to make an EC2 DescribeInstances call
        # which fails when using a proxy.
        # More details: https://github.com/awslabs/amazon-eks-ami/issues/2128
        content_type = "application/node.eks.aws"
        content      = <<-EOT
          ---
          apiVersion: node.eks.aws/v1alpha1
          kind: NodeConfig
          spec:
            featureGates:
              InstanceIdNodeName: true
        EOT
      },
      # Add private CA to EKS node trust store
      var.custom_ca_chain != null ? {
        content_type = "text/x-shellscript; charset=\"us-ascii\""
        content      = <<-EOT
          #!/bin/bash

          sudo echo "${file(var.custom_ca_chain)}" > /etc/pki/ca-trust/source/anchors/private-ca.pem
          sudo update-ca-trust
        EOT
      } : null
    ]
  }

  kubernetes_node_groups = {
    (var.name) = {
      ami_type       = "AL2023_x86_64_STANDARD"
      instance_types = ["r6i.4xlarge", "r5.4xlarge", "r4.4xlarge"]
      desired_size   = 1
      min_size       = 1
      max_size       = 10
      labels         = {}
      taints         = {}
    }
  }

  create_acm_certificate = false
  create_dns_zones       = false
  create_app_identity    = false
  create_encryption_key  = false
  install_helm_charts    = false

  tags = var.tags
}

# Managing aws-auth ourselves in Combine to set the node username
# based on {{SessionName}} to support the InstanceIdNodeName feature
module "aws_auth" {
  source  = "terraform-aws-modules/eks/aws//modules/aws-auth"
  version = "~> 20.0"

  aws_auth_roles = [{
    rolearn  = aws_iam_role.eks_nodes.arn
    username = "system:node:{{SessionName}}"
    groups = [
      "system:bootstrappers",
      "system:nodes"
    ]
  }]

  depends_on = [module.datarobot_infra.kubernetes_cluster_name]
}
