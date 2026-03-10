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

variable "letsencrypt_clusterissuers" {
  description = "Whether to create letsencrypt-prod and letsencrypt-staging ClusterIssuers"
  type        = bool
}

variable "letsencrypt_clusterissuers_email_address" {
  description = "Email address for the certificate owner. Let's Encrypt will use this to contact you about expiring certificates, and issues related to your account. Only required if letsencrypt_clusterissuers is true."
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
