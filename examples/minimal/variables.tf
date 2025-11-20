variable "pull_registry_username" {
  description = "Username to authenticate with the registry used by the application to pull container images."
  type        = string
}

variable "pull_registry_password" {
  description = "Password to authenticate with the registry used by the application to pull container images."
  type        = string
}

variable "datarobot_license" {
  description = "DataRobot license key"
  type        = string
}
