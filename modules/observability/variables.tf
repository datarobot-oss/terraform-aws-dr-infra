variable "name" {
  description = "Name to use as a prefix for created resources"
  type        = string
}

variable "kubernetes_iam_role_name" {
  description = "The role to annotate the service accounts with"
  type        = string
}

variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
  default     = {}
}
