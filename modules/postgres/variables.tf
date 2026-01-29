variable "name" {
  description = "Name to use as a prefix for created resources"
  type        = string
}

variable "vpc_id" {
  description = "ID of the VPC"
  type        = string
}

variable "ingress_cidr_blocks" {
  description = "CIDR blocks allowed for ingress on the PostgreSQL port"
  type        = list(string)
}

variable "subnets" {
  description = "List of subnet IDs to be used for the RDS postgres instance"
  type        = list(string)
}

variable "subnet_group_name" {
  description = "Name of DB subnet group"
  type        = string
  default     = null
}

variable "subnet_group_use_name_prefix" {
  description = "Determines whether to use subnet_group_name as is or create a unique name beginning with the subnet_group_name as the prefix"
  type        = bool
  default     = true
}

variable "multi_az" {
  description = "Create Postgres cluster in multi AZ mode"
  type        = bool
}

variable "password_constraints" {
  description = "Constraints to put on any generated passwords"
  type = object({
    length           = number
    min_lower        = optional(number)
    min_numeric      = optional(number)
    min_upper        = optional(number)
    special          = optional(bool)
    override_special = optional(string)
  })
  default = {
    length           = 32
    min_lower        = 1
    min_numeric      = 1
    min_upper        = 1
    override_special = "!%&*()_+-=~"
  }
}

variable "postgres_engine_version" {
  description = "The engine version to use"
  type        = string
  default     = "14.20"
}

variable "postgres_family" {
  description = "Postgres family variable to support major version upgrades"
  type        = string
  default     = "postgres14"
}

variable "postgres_instance_class" {
  description = "The instance type of the RDS instance"
  type        = string
  default     = "db.m6g.large"
}

variable "postgres_allocated_storage" {
  description = "The allocated storage in gigabytes"
  type        = number
  default     = 20
}

variable "postgres_max_allocated_storage" {
  description = "Specifies the value for Storage Autoscaling"
  type        = number
  default     = 500
}

variable "postgres_backup_retention_period" {
  description = "The days to retain backups for"
  type        = number
  default     = 7
}

variable "postgres_deletion_protection" {
  description = "The database can't be deleted when this value is set to true"
  type        = bool
  default     = false
}

variable "create_route53_cname_record" {
  description = "Whether to create a Route 53 CNAME record for the RDS instance"
  type        = bool
  default     = true
}

variable "route_53_zone_id" {
  description = "Route 53 hosted zone ID for RDS DNS records"
  type        = string
  default     = null
}

variable "tags" {
  description = "A map of tags to add to all created resources"
  type        = map(string)
}
