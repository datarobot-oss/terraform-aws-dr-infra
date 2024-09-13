output "vpc_id" {
  description = "The ID of the VPC"
  value       = module.datarobot_infra.vpc_id
}

output "public_route53_zone_id" {
  description = "Zone ID of the public Route53 zone"
  value       = module.datarobot_infra.public_route53_zone_id
}

output "private_route53_zone_id" {
  description = "Zone ID of the private Route53 zone"
  value       = module.datarobot_infra.private_route53_zone_id
}

output "acm_certificate_arn" {
  description = "ARN of the ACM certificate used on the ingress load balancer"
  value       = module.datarobot_infra.acm_certificate_arn
}

output "ebs_kms_key_arn" {
  description = "ARN of the KMS key used to encrypt EBS volumes"
  value       = module.datarobot_infra.ebs_kms_key_arn
}

output "s3_bucket_id" {
  description = "Name of the S3 bucket to use for DataRobot application file storage"
  value       = module.datarobot_infra.s3_bucket_id
}

output "ecr_repository_urls" {
  description = "URLs of the image builder repositories"
  value       = module.datarobot_infra.ecr_repository_urls
}

output "eks_cluster_name" {
  description = "Name of the EKS cluster"
  value       = module.datarobot_infra.eks_cluster_name
}

output "app_role_arn" {
  description = "ARN of the IAM role to be assumed by the DataRobot app service accounts"
  value       = module.datarobot_infra.app_role_arn
}
