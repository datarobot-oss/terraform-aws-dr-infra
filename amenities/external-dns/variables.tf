variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
}

variable "eks_cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
}

variable "route53_zone_arn" {
  description = "ARN of the Route53 zone"
  type        = string
}

variable "route53_zone_name" {
  description = "Name of the Route53 zone"
  type        = string
}
