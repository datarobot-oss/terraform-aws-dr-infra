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

variable "multi_az" {
  description = "Create redis cluster in multi AZ mode"
  type        = bool
}

variable "redis_engine_version" {
  description = "The Elasticache engine version to use"
  type        = string
  default     = "7.1"
}

variable "redis_node_type" {
  description = "The instance type of the RDS instance"
  type        = string
  default     = "cache.t4g.medium"
}

variable "redis_snapshot_retention" {
  description = "Number of days for which ElastiCache will retain automatic cache cluster snapshots before deleting them"
  type        = number
  default     = 7
}

variable "tags" {
  description = "A map of tags to add to all created resources"
  type        = map(string)
}
