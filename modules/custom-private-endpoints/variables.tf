variable "name" {
  description = "Name to use as a prefix for created resources"
  type        = string
}

variable "vpc_id" {
  description = "ID of the VPC"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR of the VPC"
  type        = string
}

variable "subnets" {
  description = "List of subnet IDs to be used for the RDS postgres instance"
  type        = list(string)
}

variable "tags" {
  description = "A map of tags to add to all created resources"
  type        = map(string)
}

variable "endpoint_config" {
  description = "Configuration for the specific endpoint"
  type = object({
    service_name     = string
    private_dns_zone = optional(string, "")
    private_dns_name = optional(string, "")
  })
}
