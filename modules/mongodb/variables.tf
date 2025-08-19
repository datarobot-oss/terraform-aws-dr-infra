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
  description = "List of subnet IDs to be used for the MongoDB Atlas private endpoint"
  type        = list(string)
}

variable "mongodb_version" {
  description = "MongoDB version"
  type        = string
}

variable "atlas_org_id" {
  description = "Atlas organization ID"
  type        = string
}

variable "termination_protection_enabled" {
  description = "Enable protection to avoid accidental production cluster termination"
  type        = bool
}

variable "db_audit_enable" {
  type        = bool
  description = "Enable database auditing for production instances only(cost incurred 10%)"
}

variable "atlas_auto_scaling_disk_gb_enabled" {
  description = "Enable Atlas disk size autoscaling"
  type        = bool
}

variable "atlas_disk_size" {
  description = "Starting atlas disk size"
  type        = string
}

variable "atlas_instance_type" {
  description = "atlas instance type"
  type        = string
}

variable "mongodb_admin_username" {
  description = "MongoDB admin username"
  type        = string
}

variable "mongodb_admin_arns" {
  description = "List of AWS IAM Principal ARNs to provide admin access to"
  type        = set(string)
  default     = []
}

variable "enable_slack_alerts" {
  description = "Enable alert notifications to a Slack channel. When `true`, `slack_api_token` and `slack_notification_channel` must be set."
  type        = string
  default     = false
}

variable "slack_api_token" {
  description = "Slack API token to use for alert notifications. Required when `enable_slack_alerts` is `true`."
  type        = string
  default     = null
}

variable "slack_notification_channel" {
  description = "Slack channel to send alert notifications to. Required when `enable_slack_alerts` is `true`."
  type        = string
  default     = null
}

variable "tags" {
  description = "A map of tags to add to all created resources"
  type        = map(string)
}
