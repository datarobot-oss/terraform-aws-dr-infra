variable "name" {
  description = "Name to use as a prefix for created resources"
  type        = string
}

variable "domain_name" {
  description = "Name of the domain to use for the DataRobot application. If create_dns_zones is true then zones will be created for this domain. It is also used by ACM for DNS validation and as a domain filter by the external-dns helm chart."
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
# Network
################################################################################

variable "existing_vpc_id" {
  description = "ID of an existing VPC to use. When specified, other network variables are ignored."
  type        = string
  default     = ""
}

variable "create_network" {
  description = "Create a new Virtual Private Cloud. Ignored if an existing existing_vpc_id is specified."
  type        = bool
  default     = true
}

variable "network_address_space" {
  description = "CIDR block to be used for the new VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "network_private_endpoints" {
  description = "List of AWS services to create interface VPC endpoints for"
  type        = list(string)
  default     = ["s3"]
}


################################################################################
# DNS
################################################################################

variable "existing_public_route53_zone_id" {
  description = "ID of existing public Route53 hosted zone to use for public DNS records created by external-dns and ACM certificate validation. This is required when create_dns_zones is false and ingress_nginx and internet_facing_ingress_lb are true or when create_acm_certificate is true."
  type        = string
  default     = ""
}

variable "existing_private_route53_zone_id" {
  description = "ID of existing private Route53 hosted zone to use for private DNS records created by external-dns. This is required when create_dns_zones is false and ingress_nginx is true with internet_facing_ingress_lb false."
  type        = string
  default     = ""
}

variable "create_dns_zones" {
  description = "Create DNS zones for domain_name. Ignored if existing_public_route53_zone_id and existing_private_route53_zone_id are specified."
  type        = bool
  default     = true
}

variable "dns_zones_force_destroy" {
  description = "Force destroy the public and private Route53 zones. Ignored if an existing route53_zone_id is specified or create_dns_zones is false."
  type        = bool
  default     = false
}


################################################################################
# ACM
################################################################################

variable "existing_acm_certificate_arn" {
  description = "ARN of existing ACM certificate to use with the ingress load balancer created by the ingress_nginx module. When specified, create_acm_certificate will be ignored."
  type        = string
  default     = ""
}

variable "create_acm_certificate" {
  description = "Create a new ACM certificate for the ingress load balancer to use. Ignored if existing_acm_certificate_arn is specified."
  type        = bool
  default     = true
}


################################################################################
# Encryption Key
################################################################################

variable "existing_kms_key_arn" {
  description = "ARN of existing KMS key used for EBS volume encryption on EKS nodes. When specified, create_encryption_key will be ignored."
  type        = string
  default     = ""
}

variable "create_encryption_key" {
  description = "Create a new KMS key used for EBS volume encryption on EKS nodes. Ignored if existing_kms_key_arn is specified."
  type        = bool
  default     = true
}


################################################################################
# Storage
################################################################################

variable "existing_s3_bucket_id" {
  description = "ID of existing S3 storage bucket to use for DataRobot application file storage. When specified, all other storage variables will be ignored."
  type        = string
  default     = ""
}

variable "create_storage" {
  description = "Create a new S3 storage bucket to use for DataRobot application file storage. Ignored if an existing_s3_bucket_id is specified."
  type        = bool
  default     = true
}

variable "s3_bucket_force_destroy" {
  description = "Force destroy the public and private Route53 zones"
  type        = bool
  default     = false
}


################################################################################
# Container Registry
################################################################################

variable "create_container_registry" {
  description = "Create DataRobot image builder container repositories in Amazon Elastic Container Registry"
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

variable "ecr_repositories_force_destroy" {
  description = "Force destroy the ECR repositories. Ignored if create_container_registry is false."
  type        = bool
  default     = false
}


################################################################################
# Kubernetes
################################################################################

variable "create_kubernetes_cluster" {
  description = "Create a new Amazon Elastic Kubernetes Cluster. All kubernetes and helm chart variables are ignored if this variable is false."
  type        = bool
  default     = true
}

variable "kubernetes_cluster_version" {
  description = "EKS cluster version"
  type        = string
  default     = null
}

variable "kubernetes_cluster_access_entries" {
  description = "Map of access entries to add to the cluster"
  type        = any
  default     = {}
}

variable "kubernetes_cluster_endpoint_public_access" {
  description = "Indicates whether or not the Amazon EKS public API server endpoint is enabled"
  type        = bool
  default     = true
}

variable "kubernetes_cluster_endpoint_public_access_cidrs" {
  description = "List of CIDR blocks which can access the Amazon EKS public API server endpoint"
  type        = list(string)
  default = [
    "0.0.0.0/0"
  ]
}

variable "kubernetes_cluster_endpoint_private_access_cidrs" {
  description = "List of additional CIDR blocks allowed to access the Amazon EKS private API server endpoint. By default only the kubernetes nodes are allowed, if any other hosts such as a provisioner need to access the EKS private API endpoint they need to be added here."
  type        = list(string)
  default     = []
}

variable "existing_kubernetes_nodes_subnet_id" {
  description = "List of existing subnet IDs to be used for the EKS cluster. Required when an existing_network_id is specified. Ignored if create_network is true and no existing_network_id is specified. Subnets must adhere to VPC requirements and considerations https://docs.aws.amazon.com/eks/latest/userguide/network_reqs.html."
  type        = list(string)
  default     = []
}

variable "kubernetes_primary_nodegroup_name" {
  description = "Name of the primary EKS node group"
  type        = string
  default     = "primary"
}

variable "kubernetes_primary_nodegroup_ami_type" {
  description = "Type of Amazon Machine Image (AMI) associated with the EKS Primary Node Group. See the [AWS documentation](https://docs.aws.amazon.com/eks/latest/APIReference/API_Nodegroup.html#AmazonEKS-Type-Nodegroup-amiType) for valid values"
  type        = string
  default     = "AL2023_x86_64_STANDARD"
}

variable "kubernetes_primary_nodegroup_instance_types" {
  description = "Instance types used for the primary node group"
  type        = list(string)
  default     = ["r6a.4xlarge"]
}

variable "kubernetes_primary_nodegroup_desired_size" {
  description = "Desired number of nodes in the primary node group"
  type        = number
  default     = 5
}

variable "kubernetes_primary_nodegroup_min_size" {
  description = "Minimum number of nodes in the primary node group"
  type        = number
  default     = 3
}

variable "kubernetes_primary_nodegroup_max_size" {
  description = "Maximum number of nodes in the primary node group"
  type        = number
  default     = 10
}

variable "kubernetes_primary_nodegroup_labels" {
  description = "Key-value map of Kubernetes labels to be applied to the nodes in the primary node group. Only labels that are applied with the EKS API are managed by this argument. Other Kubernetes labels applied to the EKS Node Group will not be managed."
  type        = map(string)
  default     = null
}

variable "kubernetes_primary_nodegroup_taints" {
  description = "The Kubernetes taints to be applied to the nodes in the primary node group. Maximum of 50 taints per node group"
  type        = any
  default     = {}
}

variable "kubernetes_gpu_nodegroup_name" {
  description = "Name of the GPU node group"
  type        = string
  default     = "gpu"
}

variable "kubernetes_gpu_nodegroup_ami_type" {
  description = "Type of Amazon Machine Image (AMI) associated with the EKS GPU Node Group. See the [AWS documentation](https://docs.aws.amazon.com/eks/latest/APIReference/API_Nodegroup.html#AmazonEKS-Type-Nodegroup-amiType) for valid values"
  type        = string
  default     = "AL2_x86_64_GPU"
}

variable "kubernetes_gpu_nodegroup_instance_types" {
  description = "Instance types used for the GPU node group"
  type        = list(string)
  default     = ["g4dn.2xlarge"]
}

variable "kubernetes_gpu_nodegroup_desired_size" {
  description = "Desired number of nodes in the GPU node group"
  type        = number
  default     = 0
}

variable "kubernetes_gpu_nodegroup_min_size" {
  description = "Minimum number of nodes in the GPU node group"
  type        = number
  default     = 0
}

variable "kubernetes_gpu_nodegroup_max_size" {
  description = "Maximum number of nodes in the GPU node group"
  type        = number
  default     = 10
}

variable "kubernetes_gpu_nodegroup_labels" {
  description = "Key-value map of Kubernetes labels to be applied to the nodes in the GPU node group. Only labels that are applied with the EKS API are managed by this argument. Other Kubernetes labels applied to the EKS Node Group will not be managed"
  type        = map(string)
  default = {
    "datarobot.com/node-capability" = "gpu"
  }
}

variable "kubernetes_gpu_nodegroup_taints" {
  description = "The Kubernetes taints to be applied to the nodes in the GPU node group. Maximum of 50 taints per node group"
  type        = any
  default = {
    nvidia_gpu = {
      key    = "nvidia.com/gpu"
      effect = "NO_SCHEDULE"
    }
  }
}


################################################################################
# App Identity
################################################################################

variable "create_app_identity" {
  description = "Create an IAM role for the DataRobot application service accounts"
  type        = bool
  default     = true
}

variable "datarobot_namespace" {
  description = "Kubernetes namespace in which the DataRobot application will be installed"
  type        = string
  default     = "dr-app"
}


################################################################################
# Helm Charts
################################################################################

variable "ebs_csi_driver" {
  description = "Install the aws-ebs-csi-driver helm chart to enable use of EBS for Kubernetes persistent volumes. All other ebs_csi_driver variables are ignored if this variable is false"
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
  type        = any
  default     = {}
}

variable "cluster_autoscaler" {
  description = "Install the cluster-autoscaler helm chart to enable horizontal autoscaling of the EKS cluster nodes. All other cluster_autoscaler variables are ignored if this variable is false"
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
  type        = any
  default     = {}
}

variable "aws_load_balancer_controller" {
  description = "Install the aws-load-balancer-controller helm chart to use AWS Network Load Balancers as ingress to the EKS cluster. All other aws_load_balancer_controller variables are ignored if this variable is false."
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
  type        = any
  default     = {}
}

variable "ingress_nginx" {
  description = "Install the ingress-nginx helm chart to use as the ingress controller for the EKS cluster. All other ingress_nginx variables are ignored if this variable is false."
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
  type        = any
  default     = {}
}

variable "cert_manager" {
  description = "Install the cert-manager helm chart. All other cert_manager variables are ignored if this variable is false."
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
  type        = any
  default     = {}
}

variable "external_dns" {
  description = "Install the external_dns helm chart to create DNS records for ingress resources matching the domain_name variable. All other external_dns variables are ignored if this variable is false."
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
  type        = any
  default     = {}
}

variable "nvidia_device_plugin" {
  description = "Install the nvidia-device-plugin helm chart to expose node GPU resources to the EKS cluster. All other nvidia_device_plugin variables are ignored if this variable is false."
  type        = bool
  default     = true
}

variable "nvidia_device_plugin_values" {
  description = "Path to templatefile containing custom values for the nvidia-device-plugin helm chart"
  type        = string
  default     = ""
}

variable "nvidia_device_plugin_variables" {
  description = "Variables passed to the nvidia_device_plugin_values templatefile"
  type        = any
  default     = {}
}
