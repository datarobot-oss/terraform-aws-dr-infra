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

variable "multi_az" {
  description = "Create Postgres cluster in multi AZ mode"
  type        = bool
}

variable "postgres_engine_version" {
  description = "The engine version to use"
  type        = string
  default     = "13"
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

variable "tags" {
  description = "A map of tags to add to all created resources"
  type        = map(string)
}
