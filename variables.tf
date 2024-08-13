variable "name" {
  description = "Name to use for created resources"
  type        = string
  default     = "datarobot"
}

variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
  default     = {}
}

variable "vpc_cidr_block" {
  description = "CIDR block to be used for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "kubernetes_nodes_cidr_block" {
  description = "CIDR block to use for the Kubernetes nodes"
  type        = string
  default     = "10.0.0.0/28"
}

variable "kubernetes_ingress_cidr_block" {
  description = "CIDR block to use for Kubernetes ingress"
  type        = string
  default     = "10.0.0.16/29"
}

variable "kubernetes_controlplane_cidr_block" {
  description = "CIDR block to use for the Kubernetes control plane"
  type        = string
  default     = "10.0.0.24/30"
}

variable "kubernetes_namespace" {
  description = "Namespace where the DataRobot application will be installed"
  type        = string
  default     = "drcore"
}
