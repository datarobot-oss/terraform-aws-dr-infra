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
