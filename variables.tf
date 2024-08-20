variable "name" {
  description = "Name to use for created resources"
  type        = string
  default     = "datarobot"
}

variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
  default = {
    managed-by : "terraform"
  }
}

variable "create_vpc" {
  description = "Create a new VPC"
  type        = bool
  default     = true
}

variable "vpc_cidr" {
  description = "CIDR block to be used for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "create_dns" {
  description = "Create a new Route53 zone"
  type        = bool
  default     = true
}

variable "dns_zone" {
  description = "DNS zone to use for app"
  type        = string
  default     = "rd.int.datarobot.com"
}

variable "create_acm_certificate" {
  description = "Create a new ACM SSL certificate"
  type        = bool
  default     = true
}

variable "create_s3_storage_bucket" {
  description = "Create a new S3 storage bucket"
  type        = bool
  default     = true
}

variable "create_ecr_repositories" {
  description = "Create DataRobot image builder container repositories"
  type        = bool
  default     = true
}

variable "create_eks_cluster" {
  description = "Create an EKS cluster"
  type        = bool
  default     = true
}

variable "create_app_irsa_role" {
  description = "Create IAM role for Datarobot application service account"
  type        = bool
  default     = true
}

variable "kubernetes_namespace" {
  description = "Namespace where the DataRobot application will be installed"
  type        = string
  default     = "dr-core"
}

variable "aws_loadbalancer_controller" {
  description = "Install the aws-load-balancer-controller helm chart"
  type        = bool
  default     = true
}

variable "aws_loadbalancer_controller_values" {
  description = "Custom values file for the aws-load-balancer-controller helm chart"
  type        = string
  default     = ""
}

variable "aws_loadbalancer_controller_variables" {
  description = "Variables passed to the aws_loadbalancer_controller_values templatefile"
  type        = map(string)
  default     = {}
}

variable "cert_manager" {
  description = "Install the cert-manager helm chart"
  type        = bool
  default     = true
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
  description = "Install the aws-ebs-csi-driver helm chart"
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
  description = "Install the external-dns helm chart"
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
  description = "Install the ingress-nginx helm chart"
  type        = bool
  default     = true
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
