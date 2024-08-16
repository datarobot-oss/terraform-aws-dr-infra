variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
}

variable "aws_loadbalancer_controller" {
  description = "Install the aws-load-balancer-controller helm chart"
  type        = bool
  default     = false
}

variable "cert_manager" {
  description = "Install the cert-manager helm chart"
  type        = bool
  default     = false
}

variable "cluster_autoscaler" {
  description = "Install the cluster-autoscaler helm chart"
  type        = bool
  default     = false
}

variable "ebs_csi_driver" {
  description = "Install the aws-ebs-csi-driver helm chart"
  type        = bool
  default     = false
}

variable "external_dns" {
  description = "Install the external-dns helm chart"
  type        = bool
  default     = false
}

variable "ingress_nginx" {
  description = "Install the ingress-nginx helm chart"
  type        = bool
  default     = false
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

variable "app_fqdn" {
  description = "FQDN to expose the app on"
  type        = string
}

variable "acm_certificate_arn" {
  description = "ARN of the certificate to use with the ingress NLB"
  type        = string
}

