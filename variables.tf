variable "name" {
  description = "Name to use as a prefix for created resources"
  type        = string
}

variable "domain_name" {
  description = "The domain name used in the dns and acm modules"
  type        = string
  default     = ""
}

variable "tags" {
  description = "A map of tags to add to all created resources"
  type        = map(string)
  default = {
    managed-by = "terraform"
  }
}


################################################################################
# VPC
################################################################################

variable "vpc_id" {
  description = "ID of an existing VPC. When specified, create_vpc and vpc_cidr will be ignored."
  type        = string
  default     = ""
}

variable "create_vpc" {
  description = "Create a new VPC. Ignored if an existing vpc_id is specified."
  type        = bool
  default     = true
}

variable "vpc_cidr" {
  description = "CIDR block to be used for the new VPC. Ignored if an existing vpc_id is specified or create_vpc is false."
  type        = string
  default     = "10.0.0.0/16"
}


################################################################################
# DNS
################################################################################

variable "route53_zone_id" {
  description = "ID of an existing route53 zone to use for ACM certificate validation. When specified, create_dns_zone will be ignored."
  type        = string
  default     = ""
}

variable "create_dns_zone" {
  description = "Create new public and private Route53 zones with domain name domain_name. Ignored if an existing route53_zone_id is specified."
  type        = bool
  default     = true
}


################################################################################
# ACM
################################################################################

variable "acm_certificate_arn" {
  description = "ARN of existing ACM certificate to use with the ingress load balancer created by the ingress_nginx module. When specified, create_acm_certificate will be ignored."
  type        = string
  default     = ""
}

variable "create_acm_certificate" {
  description = "Create a new ACM certificate to use with the ingress load balancer created by the ingress_nginx module. Ignored if existing acm_certificate_arn is specified. DNS validation will be performed against route53_zone_id if specified. Otherwise, it will be performed against the public zone created by the dns module."
  type        = bool
  default     = true
}


################################################################################
# KMS
################################################################################

variable "kms_key_arn" {
  description = "ARN of existing KMS key used for EBS volume encryption on EKS nodes. When specified, create_kms_key will be ignored."
  type        = string
  default     = ""
}

variable "create_kms_key" {
  description = "Create a new KMS key used for EBS volume encryption on EKS nodes. Ignored if kms_key_arn is specified."
  type        = bool
  default     = true
}


################################################################################
# S3
################################################################################

variable "s3_bucket_id" {
  description = "ID of existing S3 storage bucket to use for DataRobot application file storage. When specified, create_s3_bucket will be ignored."
  type        = string
  default     = ""
}

variable "create_s3_bucket" {
  description = "Create a new S3 storage bucket to use for DataRobot application file storage. Ignored if an existing s3_bucket_id is specified."
  type        = bool
  default     = true
}


################################################################################
# ECR
################################################################################

variable "create_ecr_repositories" {
  description = "Create DataRobot image builder container repositories"
  type        = bool
  default     = true
}

variable "ecr_repositories" {
  description = "Repositories to create"
  type        = set(string)
  default = [
    "base-image",
    "ephemeral-image",
    "managed-image",
    "custom-apps-managed-image"
  ]
}


################################################################################
# EKS
################################################################################

variable "create_eks_cluster" {
  description = "Create an EKS cluster"
  type        = bool
  default     = true
}

variable "eks_subnet_ids" {
  description = "List of existing subnet IDs to be used for the EKS cluster. Ignored if create_eks_cluster is false. Required when an existing vpc_id is specified. Subnets must adhere to VPC requirements and considerations https://docs.aws.amazon.com/eks/latest/userguide/network_reqs.html."
  type        = list(string)
  default     = []
}

variable "eks_cluster_version" {
  description = "EKS cluster version. Ignored if create_eks_cluster is false."
  type        = string
  default     = "1.30"
}

variable "eks_cluster_endpoint_public_access" {
  description = "Indicates whether or not the Amazon EKS public API server endpoint is enabled. Ignored if create_eks_cluster is false."
  type        = bool
  default     = true
}

variable "eks_cluster_endpoint_public_access_cidrs" {
  description = "List of CIDR blocks which can access the Amazon EKS public API server endpoint. Ignored if create_eks_cluster is false."
  type        = list(string)
  default = [
    "0.0.0.0/0"
  ]
}

variable "eks_cluster_endpoint_private_access_cidrs" {
  description = "List of additional CIDR blocks allowed to access the Amazon EKS private API server endpoint. By default only the kubernetes nodes are allowed, if any other hosts such as a provisioner need to access the EKS private API endpoint they need to be added here. Ignored if create_eks_cluster is false."
  type        = list(string)
  default     = []
}

variable "eks_cluster_access_entries" {
  description = "Map of access entries to add to the cluster. Ignored if create_eks_cluster is false."
  type        = any
  default     = {}
}

variable "eks_primary_nodegroup_ami_type" {
  description = "Type of Amazon Machine Image (AMI) associated with the EKS Primary Node Group. See the [AWS documentation](https://docs.aws.amazon.com/eks/latest/APIReference/API_Nodegroup.html#AmazonEKS-Type-Nodegroup-amiType) for valid values. Ignored if create_eks_cluster is false."
  type        = string
  default     = "AL2023_x86_64_STANDARD"
}

variable "eks_primary_nodegroup_instance_types" {
  description = "Instance types used for the primary node group. Ignored if create_eks_cluster is false."
  type        = list(string)
  default     = ["r6a.4xlarge"]
}

variable "eks_primary_nodegroup_min_size" {
  description = "Minimum number of nodes in the primary node group. Ignored if create_eks_cluster is false."
  type        = number
  default     = 5
}

variable "eks_primary_nodegroup_max_size" {
  description = "Maximum number of nodes in the primary node group. Ignored if create_eks_cluster is false."
  type        = number
  default     = 10
}

variable "eks_primary_nodegroup_desired_size" {
  description = "Desired number of nodes in the primary node group. Ignored if create_eks_cluster is false."
  type        = number
  default     = 5
}

variable "eks_primary_nodegroup_taints" {
  description = "The Kubernetes taints to be applied to the nodes in the primary node group. Maximum of 50 taints per node group"
  type        = any
  default     = {}
}

variable "create_eks_gpu_nodegroup" {
  description = "Whether to create a nodegroup with GPU instances. Ignored if create_eks_cluster is false."
  type        = bool
  default     = false
}

variable "eks_gpu_nodegroup_ami_type" {
  description = "Type of Amazon Machine Image (AMI) associated with the EKS GPU Node Group. See the [AWS documentation](https://docs.aws.amazon.com/eks/latest/APIReference/API_Nodegroup.html#AmazonEKS-Type-Nodegroup-amiType) for valid values. Ignored if create_eks_cluster is false."
  type        = string
  default     = "AL2_x86_64_GPU"
}

variable "eks_gpu_nodegroup_instance_types" {
  description = "Instance types used for the primary node group. Ignored if create_eks_cluster or create_eks_gpu_nodegroup is false."
  type        = list(string)
  default     = ["g4dn.2xlarge"]
}

variable "eks_gpu_nodegroup_min_size" {
  description = "Minimum number of nodes in the GPU node group. Ignored if create_eks_cluster or create_eks_gpu_nodegroup is false."
  type        = number
  default     = 1
}

variable "eks_gpu_nodegroup_max_size" {
  description = "Maximum number of nodes in the GPU node group. Ignored if create_eks_cluster or create_eks_gpu_nodegroup is false."
  type        = number
  default     = 3
}

variable "eks_gpu_nodegroup_desired_size" {
  description = "Desired number of nodes in the GPU node group. Ignored if create_eks_cluster or create_eks_gpu_nodegroup is false."
  type        = number
  default     = 1
}

variable "eks_gpu_nodegroup_taints" {
  description = "The Kubernetes taints to be applied to the nodes in the GPU node group. Maximum of 50 taints per node group"
  type        = any
  default = {
    dedicated = {
      key    = "dedicated"
      value  = "gpuGroup"
      effect = "NO_SCHEDULE"
    }
  }
}

################################################################################
# APP IRSA
################################################################################

variable "create_app_irsa_role" {
  description = "Create IAM role for DataRobot application service account"
  type        = bool
  default     = true
}

variable "kubernetes_namespace" {
  description = "Namespace where the DataRobot application will be installed. Ignored if create_app_irsa_role is false."
  type        = string
  default     = "dr-core"
}
