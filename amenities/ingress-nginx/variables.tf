variable "acm_certificate_arn" {
  description = "ARN of the certificate to use with the ingress NLB"
  type        = string
}

variable "app_hostname" {
  description = "Hostname to expose the app on"
  type        = string
}
