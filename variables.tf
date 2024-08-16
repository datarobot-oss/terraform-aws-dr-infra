variable "name" {
  description = "Name to use for created resources"
  type        = string
  default     = "datarobot"
}

variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
  default = {
    "ManagedBy" : "Terraform"
  }
}

variable "vpc_cidr" {
  description = "CIDR block to be used for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "dns_zone" {
  description = "DNS zone to use for app"
  type        = string
  default     = "rd.int.datarobot.com"
}

variable "kubernetes_namespace" {
  description = "Namespace where the DataRobot application will be installed"
  type        = string
  default     = "dr-core"
}
