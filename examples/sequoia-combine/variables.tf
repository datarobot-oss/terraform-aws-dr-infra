variable "name" {
  description = "Name of the project"
  type        = string
}

variable "region" {
  description = "AWS region to deploy into"
  type        = string
}

variable "vpc_id" {
  description = "ID of the existing VPC to deploy into"
  type        = string
}

variable "private_subnet_ids" {
  description = "List of subnet IDs within the existing `vpc_id` to deploy into"
  type        = list(string)
}

variable "bastion_private_ip" {
  description = "Private IP of existing host to provide SSH access to Kubernetes nodes"
  type        = string
  default     = null
}

variable "eks_cluster_version" {
  description = "Version of the EKS cluster"
  type        = string
  default     = "1.30"
}

variable "eks_cluster_iam_role_name" {
  description = "Name to use for the EKS cluster IAM role"
  type        = string
}

variable "eks_cluster_nodes_iam_role_name" {
  description = "Name to use for the EKS cluster nodes IAM role"
  type        = string
}

variable "eks_iam_role_permissions_boundary_name" {
  description = "Name of IAM role permissions boundary to use for the EKS cluster and node roles"
  type        = string
}

variable "custom_ca_chain" {
  description = "path to PEM-formatted CA chain file to add to EKS node trust stores"
  type        = string
  default     = null
}

variable "tags" {
  description = "Map of tags to apply to AWS resources"
  type        = map(string)
  default = {
    managed-by = "Terraform"
    env-type   = "dev"
  }
}
