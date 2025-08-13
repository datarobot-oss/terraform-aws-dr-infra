output "app_role_arn" {
  description = "ARN of the IAM role to be assumed by the DataRobot app service accounts"
  value       = module.datarobot_infra.app_role_arn
}

output "ecr_repository_urls" {
  description = "URLs of the image builder repositories"
  value       = module.datarobot_infra.ecr_repository_urls
}

output "s3_bucket_name" {
  description = "S3 bucket name to use for DataRobot application file storage"
  value       = module.datarobot_infra.s3_bucket_id
}

output "postgres_endpoint" {
  description = "RDS postgres endpoint"
  value       = split(":", module.datarobot_infra.postgres_endpoint)[0]
}

output "postgres_password" {
  description = "RDS postgres master password"
  value       = module.datarobot_infra.postgres_password
  sensitive   = true
}

output "redis_endpoint" {
  description = "Elasticache redis endpoint"
  value       = module.datarobot_infra.redis_endpoint
}

output "redis_password" {
  description = "Elasticache redis auth token"
  value       = module.datarobot_infra.redis_password
  sensitive   = true
}
