variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
}

variable "eks_cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string
}


################################################################################
# cluster-autoscaler
################################################################################

variable "install_cluster_autoscaler" {
  description = "Install the cluster-autoscaler helm chart to enable horizontal autoscaling of the EKS cluster nodes"
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


################################################################################
# aws-ebs-csi-driver
################################################################################

variable "install_ebs_csi_driver" {
  description = "Install the aws-ebs-csi-driver helm chart to enable use of EBS for Kubernetes persistent volumes"
  type        = bool
  default     = true
}

variable "ebs_csi_driver_kms_arn" {
  description = "ARN of the KMS key used to encrypt EBS volumes"
  type        = string
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


################################################################################
# aws-load-balancer-controller
################################################################################

variable "install_aws_load_balancer_controller" {
  description = "Install the aws-load-balancer-controller helm chart to use AWS Network Load Balancers as ingress to the EKS cluster"
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


################################################################################
# ingress-nginx
################################################################################

variable "install_ingress_nginx" {
  description = "Install the ingress-nginx helm chart to use as the ingress controller for the EKS cluster"
  type        = bool
  default     = true
}

variable "ingress_nginx_acm_certificate_arn" {
  description = "ARN of the certificate to use with the ingress NLB"
  type        = string
}

variable "ingress_nginx_internet_facing" {
  description = "Connect to the DataRobot application via an internet-facing load balancer. If dns is enabled, create a public route53 zone"
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



################################################################################
# cert-manager
################################################################################

variable "install_cert_manager" {
  description = "Install the cert-manager helm chart to manage certificates within the EKS cluster"
  type        = bool
  default     = true
}

variable "cert_manager_hosted_zone_arns" {
  description = "Route53 hosted zone ARNs to allow Cert manager to manage records"
  type        = list(string)
  default     = []
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


################################################################################
# external-dns
################################################################################

variable "install_external_dns" {
  description = "Install the external-dns helm chart to manage DNS records for EKS ingress and service resources"
  type        = bool
  default     = true
}

variable "external_dns_hosted_zone_arn" {
  description = "Route53 hosted zone ARN to allow external-dns to manage records"
  type        = string
  default     = ""
}

variable "external_dns_hosted_zone_id" {
  description = "Route53 hosted zone ID to pass as a zoneFilter to the external-dns helm chart"
  type        = string
  default     = ""
}

variable "external_dns_hosted_zone_name" {
  description = "Route53 hosted zone name to pass as a domainFilter to the external-dns helm chart"
  type        = string
  default     = ""
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
