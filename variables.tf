variable "name" {
  description = "Name to use as a prefix for created resources"
  type        = string
}

variable "domain_name" {
  description = "The domain name used in the dns and acm modules."
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

variable "vpc_id" {
  description = "ID of an existing VPC. When specified, create_vpc and vpc_cidr will be ignored."
  type        = string
  default     = ""
}

variable "eks_subnet_ids" {
  description = "List of existing subnet IDs to be used for the EKS cluster. Ignored if existing vpc_id is not specified. Ensure the subnets adhere to VPC requirements and considerations https://docs.aws.amazon.com/eks/latest/userguide/network_reqs.html."
  type        = list(string)
  default     = []
}

variable "create_vpc" {
  description = "Create a new VPC. This variable is ignored if an existing vpc_id is specified."
  type        = bool
  default     = true
}

variable "vpc_cidr" {
  description = "CIDR block to be used for the new VPC. Ignored if an existing vpc_id is specified or create_vpc is false."
  type        = string
  default     = "10.0.0.0/16"
}

variable "route53_zone_id" {
  description = "ID of an existing route53 zone. When specified, create_dns_zone will be ignored."
  type        = string
  default     = ""
}

variable "create_dns_zone" {
  description = "Create new public and private Route53 zones with domain name domain_name. Ignored if an existing route53_zone_id is specified."
  type        = bool
  default     = true
}

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

variable "create_eks_cluster" {
  description = "Create an EKS cluster"
  type        = bool
  default     = true
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

variable "eks_cluster_access_entries" {
  description = "Map of access entries to add to the cluster. Ignored if create_eks_cluster is false."
  type        = any
  default     = {}
}

variable "eks_primary_nodegroup_instance_types" {
  description = "Instance types used for the primary node group. Ignored if create_eks_cluster is false."
  type        = list(string)
  default     = ["r6i.4xlarge"]
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
  default     = 6
}

variable "create_eks_gpu_nodegroup" {
  description = "Whether to create a nodegroup with GPU instances. Ignored if create_eks_cluster is false."
  type        = bool
  default     = false
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

variable "aws_load_balancer_controller" {
  description = "Install the aws-load-balancer-controller helm chart to use AWS Network Load Balancers as ingress to the EKS cluster. Ignored if create_eks_cluster is false."
  type        = bool
  default     = true
}

variable "aws_load_balancer_controller_values" {
  description = "Path to templatefile containing custom values for the aws-load-balancer-controller helm chart"
  type        = string
  default     = ""
}

variable "aws_load_balancer_controller_variables" {
  description = "Variables passed to the aws_load_balancer_controller_values templatefile"
  type        = map(string)
  default     = {}
}

variable "cert_manager" {
  description = "Install the cert-manager helm chart to manage certificates within the EKS cluster. Ignored if create_eks_cluster is false."
  type        = bool
  default     = true
}

variable "cert_manager_values" {
  description = "Path to templatefile containing custom values for the cert-manager helm chart"
  type        = string
  default     = ""
}

variable "cert_manager_variables" {
  description = "Variables passed to the cert_manager_values templatefile"
  type        = map(string)
  default     = {}
}

variable "cluster_autoscaler" {
  description = "Install the cluster-autoscaler helm chart to enable horizontal autoscaling of the EKS cluster nodes. Ignored if create_eks_cluster is false."
  type        = bool
  default     = true
}

variable "cluster_autoscaler_values" {
  description = "Path to templatefile containing custom values for the cluster-autoscaler helm chart"
  type        = string
  default     = ""
}

variable "cluster_autoscaler_variables" {
  description = "Variables passed to the cluster_autoscaler_values templatefile"
  type        = map(string)
  default     = {}
}

variable "ebs_csi_driver" {
  description = "Install the aws-ebs-csi-driver helm chart to enable use of EBS for Kubernetes persistent volumes. Ignored if create_eks_cluster is false."
  type        = bool
  default     = true
}

variable "ebs_csi_driver_values" {
  description = "Path to templatefile containing custom values for the aws-ebs-csi-driver helm chart"
  type        = string
  default     = ""
}

variable "ebs_csi_driver_variables" {
  description = "Variables passed to the ebs_csi_driver_values templatefile"
  type        = map(string)
  default     = {}
}

variable "external_dns" {
  description = "Install the external-dns helm chart to manage DNS records for EKS ingress and service resources. Ignored if create_eks_cluster is false."
  type        = bool
  default     = true
}

variable "external_dns_values" {
  description = "Path to templatefile containing custom values for the external-dns helm chart"
  type        = string
  default     = ""
}

variable "external_dns_variables" {
  description = "Variables passed to the external_dns_values templatefile"
  type        = map(string)
  default     = {}
}

variable "ingress_nginx" {
  description = "Install the ingress-nginx helm chart to use as the ingress controller for the EKS cluster. Ignored if create_eks_cluster is false."
  type        = bool
  default     = true
}

variable "internet_facing_ingress_lb" {
  description = "Determines the type of NLB created for EKS ingress. If true, an internet-facing NLB will be created. If false, an internal NLB will be created. Ignored when ingress_nginx is false."
  type        = bool
  default     = true
}

variable "ingress_nginx_values" {
  description = "Path to templatefile containing custom values for the ingress-nginx helm chart."
  type        = string
  default     = ""
}

variable "ingress_nginx_variables" {
  description = "Variables passed to the ingress_nginx_values templatefile"
  type        = map(string)
  default     = {}
}
