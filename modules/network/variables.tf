variable "name" {
  description = "Name to use as a prefix for created resources"
  type        = string
}

variable "network_address_space" {
  description = "The CIDR block for the VPC"
  type        = string
}

variable "availability_zones" {
  description = "Number of availability zones to deploy into"
  type        = number
}

variable "interface_endpoints" {
  description = "List of AWS services to create interface VPC endpoints for"
  type        = list(string)
  default = [
    "s3",
    "ec2",
    "ecr.api",
    "ecr.dkr",
    "elasticloadbalancing",
    "logs",
    "sts",
    "eks-auth",
    "eks"
  ]
}

variable "s3_private_dns_enabled" {
  description = "Enable private DNS for the S3 VPC endpoint. Currently not supported in GovCloud regions https://docs.aws.amazon.com/govcloud-us/latest/UserGuide/govcloud-s3.html."
  type        = bool
  default     = true
}

variable "zone_id" {
  description = "ID of Route53 hosted zone to create S3 service CNAME record in. Ignored when `s3_private_dns_enabled` is `true`."
  type        = string
  default     = null
}

variable "fips_enabled" {
  description = "Enable FIPS endpoints for AWS services"
  type        = bool
  default     = false
}

variable "enable_vpc_flow_logs" {
  description = "Enable VPC Flow Logs for the created VPC"
  type        = bool
  default     = false
}

variable "vpc_flow_log_retention" {
  description = "Number of days to retain VPC flow log events. Set to `0` to keep logs indefinitely"
  type        = number
  default     = 7
}

variable "network_firewall" {
  description = "Create an AWS Network Firewall"
  type        = bool
  default     = false
}

variable "network_firewall_delete_protection" {
  description = "Enable delete protection for the AWS Network Firewall"
  type        = bool
  default     = false
}

variable "network_firewall_subnet_change_protection" {
  description = "Enable subnet change protection for the AWS Network Firewall"
  type        = bool
  default     = false
}

variable "network_firewall_create_logging_configuration" {
  description = "Create logging configuration for the AWS Network Firewall"
  type        = bool
  default     = false
}

variable "network_firewall_alert_log_retention" {
  description = "Number of days to retain NFW alert logs. Set to `0` to keep logs indefinitely"
  type        = number
  default     = 7
}

variable "network_firewall_flow_log_retention" {
  description = "Number of days to retain NFW flow logs. Set to `0` to keep logs indefinitely"
  type        = number
  default     = 7
}

variable "network_firewall_policy_stateless_default_actions" {
  description = "Set of actions to take on a packet if it does not match any of the stateless rules in the policy. You must specify one of the standard actions including: `aws:drop`, `aws:pass`, or `aws:forward_to_sfe`"
  type        = list(string)
  default     = ["aws:pass"]
}

variable "network_firewall_policy_stateless_fragment_default_actions" {
  description = "Set of actions to take on a fragmented packet if it does not match any of the stateless rules in the policy. You must specify one of the standard actions including: `aws:drop`, `aws:pass`, or `aws:forward_to_sfe`"
  type        = list(string)
  default     = ["aws:drop"]
}

variable "network_firewall_policy_stateless_rule_group_reference" {
  description = "Set of configuration blocks containing references to the stateless rule groups that are used in the policy. See [Stateless Rule Group Reference](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/networkfirewall_firewall_policy#stateless-rule-group-reference) for details"
  type = map(object({
    priority     = number
    resource_arn = string
  }))
  default = null
}

variable "network_firewall_policy_stateful_rule_group_reference" {
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
