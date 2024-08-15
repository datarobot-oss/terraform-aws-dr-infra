output "app_role_arn" {
  description = "ARN of the IAM role to be assumed by the DataRobot app service accounts"
  value       = module.app_irsa_role.iam_role_arn
}

output "app_fqdn" {
  description = "FQDN of the DataRobot application"
  value       = local.app_fqdn
}

output "ecr_repository_urls" {
  description = "URLs of the image builder repositories"
  value       = [for repo in module.ecr : repo.repository_url]
}

output "s3_bucket_name" {
  description = "S3 bucket name to use for DataRobot application file storage"
  value       = module.storage.s3_bucket_id
}

output "s3_bucket_regional_domain" {
  description = "S3 bucket region-specific domain name"
  value       = module.storage.s3_bucket_bucket_regional_domain_name
}
