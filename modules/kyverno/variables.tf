variable "eks_cluster_name" {
  description = "EKS cluster name"
  type        = string
  default     = null
}

variable "chart_version" {
  description = "Version of the helm chart to install"
  type        = string
  default     = null
}

variable "values_overrides" {
  description = "Values in raw yaml format to pass to helm."
  type        = string
  default     = null
}

variable "install_policies" {
  description = "Install the Pod Security Standard policies"
  type        = bool
  default     = true
}

variable "policies_chart_version" {
  description = "Version of the kyverno-policies helm chart to install"
  type        = string
  default     = null
}

variable "policies_values_overrides" {
  description = "Values in raw yaml format to pass to the kyverno-policies helm chart."
  type        = string
  default     = null
}

variable "notation_aws" {
  description = "Install kyverno-notation-aws helm chart which executes the AWS Signer plugin for Notation to verify image signatures and attestations."
  type        = bool
  default     = false
}

variable "notation_aws_chart_version" {
  description = "Version of the kyverno-notation-aws helm chart to install"
  type        = string
  default     = null
}

variable "notation_aws_values_overrides" {
  description = "Values in raw yaml format to pass to the kyverno-notation-aws helm chart."
  type        = string
  default     = null
}

variable "signer_profile_arn" {
  description = "ARN of the signer profile"
  type        = string
  default     = null
}
