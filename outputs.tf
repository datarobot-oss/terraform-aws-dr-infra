################################################################################
# Network
################################################################################

output "vpc_id" {
  description = "The ID of the VPC"
  value       = try(module.network[0].vpc_id, null)
}

output "vpc_cidr_block" {
  description = "The CIDR block of the VPC"
  value       = try(module.network[0].vpc_cidr_block, null)
}

output "vpc_public_subnets" {
  description = "List of IDs of public subnets"
  value       = try(module.network[0].public_subnets, null)
}

output "vpc_private_subnets" {
  description = "List of IDs of private subnets"
  value       = try(module.network[0].private_subnets, null)
}


################################################################################
# DNS
################################################################################

output "public_route53_zone_id" {
  description = "Zone ID of the public Route53 zone"
  value       = try(module.dns[0].route53_zone_zone_id["public"], null)
}

output "public_route53_zone_arn" {
  description = "Zone ARN of the public Route53 zone"
  value       = try(module.dns[0].route53_zone_zone_arn["public"], null)
}

output "private_route53_zone_id" {
  description = "Zone ID of the private Route53 zone"
  value       = try(module.dns[0].route53_zone_zone_id["public"], null)
}

output "private_route53_zone_arn" {
  description = "Zone ARN of the private Route53 zone"
  value       = try(module.dns[0].route53_zone_zone_arn["public"], null)
}


################################################################################
# ACM
################################################################################

output "acm_certificate_arn" {
  description = "ARN of the ACM certificate"
  value       = try(module.acm[0].acm_certificate_arn, null)
}


################################################################################
# Encryption Key
################################################################################

output "ebs_encryption_key_id" {
  description = "ARN of the EBS KMS key"
  value       = try(module.encryption_key[0].key_arn, null)
}


################################################################################
# Storage
################################################################################

output "s3_bucket_id" {
  description = "Name of the S3 bucket"
  value       = try(module.storage[0].s3_bucket_id, null)
}


################################################################################
# Container Registry
################################################################################

output "ecr_repository_urls" {
  description = "URLs of the image builder repositories"
  value       = var.create_container_registry ? [for repo in module.container_registry : repo.repository_url] : null
}


################################################################################
# Kubernetes
################################################################################

output "kubernetes_cluster_name" {
  description = "Name of the EKS cluster"
  value       = try(module.kubernetes[0].cluster_name, null)
}

output "kubernetes_cluster_endpoint" {
  description = "Endpoint for your Kubernetes API server"
  value       = try(module.kubernetes[0].cluster_endpoint, null)
}

output "kubernetes_cluster_certificate_authority_data" {
  description = "Base64 encoded certificate data required to communicate with the cluster"
  value       = try(module.kubernetes[0].cluster_certificate_authority_data, null)
}

output "kubernetes_cluster_node_groups" {
  description = "EKS cluster node groups"
  value       = try(module.kubernetes[0].eks_managed_node_groups, null)
}


################################################################################
# App Identity
################################################################################

output "app_role_arn" {
  description = "ARN of the IAM role to be assumed by the DataRobot app service accounts"
  value       = try(module.app_identity[0].iam_role_arn, null)
}
