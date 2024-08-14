variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
}

variable "eks_cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
}
