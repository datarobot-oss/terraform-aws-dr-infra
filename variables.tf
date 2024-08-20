variable "name" {
  description = "Name to use as a prefix for created resources"
  type        = string
}

variable "app_fqdn" {
  description = "FQDN to be used to access the DataRobot application"
  type        = string
}

variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
  default = {
    managed-by : "terraform"
  }
}

variable "public" {
  description = "Connect to the DataRobot application via an internet-facing load balancer. If dns is enabled, create a public route53 zone"
  type        = bool
}

variable "vpc_id" {
  description = "ID of existing VPC"
  type        = string
  default     = ""
}

variable "create_vpc" {
  description = "Create a new VPC. Ignored when existing vpc_id is specified."
  type        = bool
}

variable "vpc_cidr" {
  description = "CIDR block to be used for the VPC. Ignored when existing vpc_id is specified or create_vpc is false"
  type        = string
}

variable "eks_subnets" {
  description = "List of existing subnet IDs to be used for the EKS cluster"
  type        = list(string)
  default     = []
}

variable "route53_zone_arn" {
  description = "ARN of existing route53 zone"
  type        = string
  default     = ""
}

variable "route53_zone_id" {
  description = "ID of existing route53 zone"
  type        = string
  default     = ""
}

variable "create_dns_zone" {
  description = "Create a new Route53 zone"
  type        = bool
}

variable "acm_certificate_arn" {
  description = "ARN of existing ACM certificate to use on the ingress load balancer"
  type        = string
  default     = ""
}

variable "create_acm_certificate" {
  description = "Create a new ACM SSL certificate"
  type        = bool
}

variable "s3_bucket_id" {
  description = "ID of existing S3 storage bucket"
  type = string
  default = ""
}


variable "create_s3_storage_bucket" {
  description = "Create a new S3 storage bucket"
  type        = bool
}

variable "create_ecr_repositories" {
  description = "Create DataRobot image builder container repositories"
  type        = bool
}

variable "eks_cluster_name" {
  description = "Name of existing EKS cluster"
  type        = string
  default     = ""
}

variable "create_eks_cluster" {
  description = "Create an EKS cluster"
  type        = bool
}

variable "create_app_irsa_role" {
  description = "Create IAM role for Datarobot application service account"
  type        = bool
}

variable "kubernetes_namespace" {
  description = "Namespace where the DataRobot application will be installed"
  type        = string
}

variable "aws_load_balancer_controller" {
  description = "Install the aws-load-balancer-controller helm chart"
  type        = bool
}

variable "aws_load_balancer_controller_values" {
  description = "Custom values file for the aws-load-balancer-controller helm chart"
  type        = string
  default     = ""
}

variable "aws_load_balancer_controller_variables" {
  description = "Variables passed to the aws_load_balancer_controller_values templatefile"
  type        = map(string)
  default     = {}
}

variable "cert_manager" {
  description = "Install the cert-manager helm chart"
  type        = bool
}

variable "cert_manager_values" {
  description = "Custom values file for the cert-manager helm chart"
  type        = string
  default     = ""
}

variable "cert_manager_variables" {
  description = "Variables passed to the cert_manager_values templatefile"
  type        = map(string)
  default     = {}
}

variable "cluster_autoscaler" {
  description = "Install the cluster-autoscaler helm chart"
  type        = bool
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
  description = "Install the aws-ebs-csi-driver helm chart"
  type        = bool
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
  description = "Install the external-dns helm chart"
  type        = bool
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
  description = "Install the ingress-nginx helm chart"
  type        = bool
}

variable "ingress_nginx_values" {
  description = "Path to templatefile containing custom values for the ingress-nginx helm chart"
  type        = string
  default     = ""
}

variable "ingress_nginx_variables" {
  description = "Variables passed to the ingress_nginx_values templatefile"
  type        = map(string)
  default     = {}
}
