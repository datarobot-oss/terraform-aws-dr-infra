variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
}

variable "acm_certificate_arn" {
  description = "ARN of the certificate to use with the ingress NLB"
  type        = string
}

variable "public" {
  description = "Connect to the DataRobot application via an internet-facing load balancer. If dns is enabled, create a public route53 zone"
  type        = bool
  default     = true
}

variable "custom_values_templatefile" {
  description = "Custom values templatefile to pass to the helm chart"
  type        = string
  default     = ""
}

variable "custom_values_variables" {
  description = "Variables for the custom values templatefile"
  type        = map(string)
  default     = {}
}
