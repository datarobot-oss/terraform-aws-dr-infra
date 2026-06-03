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

variable "existing_vpc_id" {
  description = "ID of an existing VPC to deploy resources into."
  type        = string
}

variable "provisioner_ip" {
  description = "IP address of the host running `terraform apply`. This IP is granted access to the private EKS cluster API endpoint."
  type        = string
}

variable "ingress_allowed_cidr" {
  description = "CIDR block allowed to access the internal ingress load balancer."
  type        = string
}

variable "tags" {
  description = "Tags to apply to created resources."
  type        = map(string)
  default = {
    managed-by = "terraform"
  }
}
