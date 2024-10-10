variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
}

variable "kubernetes_cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
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
