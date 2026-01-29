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
  description = "List of subnet IDs to be used for the ElastiCache redis instance"
  type        = list(string)
}

variable "subnet_group_name" {
  description = "The name of the Elasticache Redis subnet group"
  type        = string
  default     = null
}

variable "multi_az" {
  description = "Create redis cluster in multi AZ mode"
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
    override_special = "-"
  }
}

variable "redis_engine_version" {
  description = "The Elasticache engine version to use"
  type        = string
  default     = "7.1"
}

variable "redis_node_type" {
  description = "The instance type of the Redis instance"
  type        = string
  default     = "cache.t4g.medium"
}

variable "redis_snapshot_retention" {
  description = "Number of days for which ElastiCache will retain automatic cache cluster snapshots before deleting them"
  type        = number
  default     = 7
}

variable "create_route53_cname_record" {
  description = "Whether to create a Route 53 CNAME record for the RDS instance"
  type        = bool
  default     = true
}

variable "route_53_zone_id" {
  description = "Route 53 hosted zone ID for Redis DNS records"
  type        = string
  default     = null
}

variable "tags" {
  description = "A map of tags to add to all created resources"
  type        = map(string)
}
