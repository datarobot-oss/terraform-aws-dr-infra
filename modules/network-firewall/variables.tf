variable "name" {
  description = "Name to use as a prefix for created resources"
  type        = string
}

variable "azs" {
  description = "Names of Availability Zones to put firewall endpoints in"
  type        = list(string)
}

variable "vpc_id" {
  description = "ID of the VPC"
  type        = string
}

variable "firewall_subnet_cidrs" {
  description = "CIDRs to use for the firewall subnets"
  type        = list(string)
}

variable "public_subnet_cidrs" {
  description = "CIDRs to use for the public subnets"
  type        = list(string)
}

variable "private_route_table_ids" {
  description = "IDs of private route tables"
  type        = list(string)
}

variable "delete_protection" {
  description = "Enable delete protection for the AWS Network Firewall"
  type        = bool
  default     = false
}

variable "subnet_change_protection" {
  description = "Enable subnet change protection for the AWS Network Firewall"
  type        = bool
  default     = false
}

variable "create_logging_configuration" {
  description = "Create logging configuration for the AWS Network Firewall"
  type        = bool
  default     = false
}

variable "alert_log_retention" {
  description = "Number of days to retain NFW alert logs. Set to `0` to keep logs indefinitely"
  type        = number
  default     = 7
}

variable "flow_log_retention" {
  description = "Number of days to retain NFW flow logs. Set to `0` to keep logs indefinitely"
  type        = number
  default     = 7
}

variable "policy_stateless_default_actions" {
  description = "Set of actions to take on a packet if it does not match any of the stateless rules in the policy. You must specify one of the standard actions including: `aws:drop`, `aws:pass`, or `aws:forward_to_sfe`"
  type        = list(string)
  default     = ["aws:pass"]
}

variable "policy_stateless_fragment_default_actions" {
  description = "Set of actions to take on a fragmented packet if it does not match any of the stateless rules in the policy. You must specify one of the standard actions including: `aws:drop`, `aws:pass`, or `aws:forward_to_sfe`"
  type        = list(string)
  default     = ["aws:drop"]
}

variable "policy_stateless_rule_group_reference" {
  description = "Set of configuration blocks containing references to the stateless rule groups that are used in the policy. See [Stateless Rule Group Reference](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/networkfirewall_firewall_policy#stateless-rule-group-reference) for details"
  type = map(object({
    priority     = number
    resource_arn = string
  }))
  default = null
}

variable "policy_stateful_rule_group_reference" {
  description = "Set of configuration blocks containing references to the stateful rule groups that are used in the policy. See [Stateful Rule Group Reference](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/networkfirewall_firewall_policy#stateful-rule-group-reference) for details"
  type = map(object({
    deep_threat_inspection = optional(bool)
    override = optional(object({
      action = optional(string)
    }))
    priority     = optional(number)
    resource_arn = string
  }))
  default = null
}

variable "tags" {
  description = "A map of tags to add to all created resources"
  type        = map(string)
}
