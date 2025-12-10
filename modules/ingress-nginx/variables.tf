variable "chart_version" {
  description = "Version of the helm chart to install"
  type        = string
  default     = null
}

variable "acm_certificate_arn" {
  description = "ARN of the certificate to use with the ingress NLB"
  type        = string
  default     = null
}

variable "internet_facing_ingress_lb" {
  description = "Connect to the DataRobot application via an internet-facing load balancer. If dns is enabled, create a public route53 zone"
  type        = bool
  default     = true
}

variable "eks_cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
  default     = null
}

variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
}

variable "values_overrides" {
  description = "Values in raw yaml format to pass to helm."
  type        = string
  default     = null
}
