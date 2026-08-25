variable "name" {
  description = "Name to apply to created resources."
  type        = string
}

variable "environment" {
  description = "Type of environment. Must be one of 'dev', 'staging', or 'prod'."
  type        = string

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be one of 'dev', 'staging', or 'prod'."
  }
}

variable "account_id" {
  description = "ID of the AWS account to deploy resources in."
  type        = string
}

variable "region" {
  description = "AWS region to deploy resources in."
  type        = string
}

variable "domain_name" {
  description = "Domain name to use for the application."
  type        = string
}

variable "email_address" {
  description = "Email address for the LetsEncrypt ACME certificate owner. Let's Encrypt will use this to contact you about expiring certificates, and issues related to your account."
  type        = string
}

variable "tags" {
  description = "Tags to apply to created resources."
  type        = map(string)
  default = {
    managed-by = "terraform"
  }
}
