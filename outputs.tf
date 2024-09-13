################################################################################
# VPC
################################################################################

output "vpc_id" {
  description = "The ID of the VPC"
  value       = try(module.vpc[0].vpc_id, null)
}


################################################################################
# DNS
################################################################################

output "public_route53_zone_id" {
  description = "Zone ID of the public Route53 zone"
  value       = try(module.dns[0].route53_zone_zone_id[local.public_route53_zone_key], null)
}

output "public_route53_zone_arn" {
  description = "Zone ARN of the public Route53 zone"
  value       = try(module.dns[0].route53_zone_zone_arn[local.public_route53_zone_key], null)
}

output "private_route53_zone_id" {
  description = "Zone ID of the private Route53 zone"
  value       = try(module.dns[0].route53_zone_zone_id[local.private_route53_zone_key], null)
}

output "private_route53_zone_arn" {
  description = "Zone ARN of the private Route53 zone"
  value       = try(module.dns[0].route53_zone_zone_arn[local.private_route53_zone_key], null)
}


################################################################################
# ACM
################################################################################

output "acm_certificate_arn" {
  description = "ARN of the ACM certificate"
  value       = try(module.acm[0].acm_certificate_arn, null)
}


################################################################################
# KMS
################################################################################

output "ebs_kms_key_arn" {
  description = "ARN of the EBS KMS key"
  value       = try(module.kms[0].key_arn, null)
}


################################################################################
# S3
################################################################################

output "s3_bucket_id" {
  description = "Name of the S3 bucket"
  value       = try(module.storage[0].s3_bucket_id, null)
}


################################################################################
# ECR
################################################################################

output "ecr_repository_urls" {
  description = "URLs of the image builder repositories"
  value       = [for repo in module.ecr : repo.repository_url]
}


################################################################################
# EKS
################################################################################

output "eks_cluster_name" {
  description = "Name of the EKS cluster"
  value       = try(module.eks[0].cluster_name, null)
}

output "eks_cluster_endpoint" {
  description = "Endpoint for your Kubernetes API server"
  value       = try(module.eks[0].cluster_endpoint, null)
}

output "eks_cluster_certificate_authority_data" {
  description = "Base64 encoded certificate data required to communicate with the cluster"
  value       = try(module.eks[0].cluster_certificate_authority_data, null)
}


################################################################################
# APP IRSA
################################################################################

output "app_role_arn" {
  description = "ARN of the IAM role to be assumed by the DataRobot app service accounts"
  value       = try(module.app_irsa_role[0].iam_role_arn, null)
}
