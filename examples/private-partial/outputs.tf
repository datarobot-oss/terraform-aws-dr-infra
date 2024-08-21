output "app_role_arn" {
  description = "ARN of the IAM role to be assumed by the DataRobot app service accounts"
  value       = module.datarobot-infra.app_role_arn
}

output "app_fqdn" {
  description = "FQDN of the DataRobot application"
  value       = module.datarobot-infra.app_fqdn
}

output "ecr_repository_urls" {
  description = "URLs of the image builder repositories"
  value       = module.datarobot-infra.ecr_repository_urls
}

output "s3_bucket_name" {
  description = "S3 bucket name to use for DataRobot application file storage"
  value       = module.datarobot-infra.s3_bucket_name
}
