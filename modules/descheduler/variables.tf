variable "chart_version" {
  description = "Semver range (helm --version constraint) of the helm chart to install"
  type        = string

}

variable "values_overrides" {
  description = "Values in raw yaml format to pass to helm."
  type        = string
  default     = null
}
