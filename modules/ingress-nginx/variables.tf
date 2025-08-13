variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
}

variable "acm_certificate_arn" {
  description = "ARN of the certificate to use with the ingress NLB"
  type        = string
}

variable "internet_facing_ingress_lb" {
  description = "Connect to the DataRobot application via an internet-facing load balancer. If dns is enabled, create a public route53 zone"
  type        = bool
  default     = true
}

variable "create_vpce_service" {
  description = "Create a VPC endpoint service for the NLB"
  type        = bool
  default     = false
}

variable "vpce_service_allowed_principals" {
  description = "The ARNs of one or more principals allowed to discover the endpoint service."
  type        = list(string)
  default     = null
}

variable "vpce_service_private_dns_name" {
  description = "Private DNS name to use for the VPCE service"
  type        = string
  default     = null
}

variable "eks_cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
  default     = null
}

variable "custom_values_templatefile" {
  description = "Custom values templatefile to pass to the helm chart"
  type        = string
  default     = ""
}

variable "custom_values_variables" {
  description = "Variables for the custom values templatefile"
  type        = any
  default     = {}
}
