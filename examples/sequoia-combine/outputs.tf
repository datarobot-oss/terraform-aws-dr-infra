output "kubernetes_cluster_name" {
  description = "EKS cluster name"
  value       = module.datarobot_infra.kubernetes_cluster_name
}

output "ecr_repository_urls" {
  description = "ECR repository URLs"
  value       = module.datarobot_infra.ecr_repository_urls
}

output "s3_bucket_id" {
  description = "S3 bucket name"
  value       = module.datarobot_infra.s3_bucket_id
}
