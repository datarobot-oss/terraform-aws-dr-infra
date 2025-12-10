variable "chart_version" {
  description = "Version of the helm chart to install"
  type        = string
  default     = null
}

variable "kubernetes_cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
}

variable "route53_zone_arn" {
  description = "ARN of the Route53 zone"
  type        = string
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
