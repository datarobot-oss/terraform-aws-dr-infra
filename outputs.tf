output "app_role_arn" {
  description = "ARN of the IAM role to be assumed by the DataRobot app service accounts"
  value       = var.create_app_irsa_role ? module.app_irsa_role[0].iam_role_arn : ""
}

output "ecr_repository_urls" {
  description = "URLs of the image builder repositories"
  value       = [for repo in module.ecr : repo.repository_url]
}

output "s3_bucket_name" {
  description = "S3 bucket name to use for DataRobot application file storage"
  value       = local.s3_bucket_id
}
