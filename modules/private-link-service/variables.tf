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

variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
}

variable "ingress_lb_arns" {
  description = "ARNs of ingress load balancers to expose as a VPC Endpoint Service. When specified, the load balancers created by the ingress_nginx module will not be used."
  type        = list(string)
  default     = null
}
