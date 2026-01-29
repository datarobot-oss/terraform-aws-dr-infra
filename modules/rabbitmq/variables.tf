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

variable "engine_version" {
  type        = string
  description = "Version of the broker engine. See the [AmazonMQ Broker Engine docs](https://docs.aws.amazon.com/amazon-mq/latest/developer-guide/broker-engine.html) for supported versions."
}

variable "auto_minor_version_upgrade" {
  description = "Whether to automatically upgrade to new minor versions of brokers as Amazon MQ makes releases available."
  type        = bool
}

variable "host_instance_type" {
  description = "Broker's instance type. For example, `mq.t3.micro`, `mq.m5.large`."
  type        = string
}

variable "authentication_strategy" {
  description = "Authentication strategy used to secure the broker"
  type        = string
}

variable "username" {
  description = "RabbitMQ broker usernmae"
  type        = string
}

variable "log" {
  type        = bool
  description = "Export logs to CloudWatch"
}

variable "log_retention" {
  type        = string
  description = "CloudWatch log retention"
  default     = 90
}

variable "tags" {
  description = "A map of tags to add to all created resources"
  type        = map(string)
}
