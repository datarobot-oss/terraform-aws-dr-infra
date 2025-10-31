################################################################################
# Network
################################################################################

output "vpc_id" {
  description = "The ID of the VPC"
  value       = local.vpc_id
}

output "vpc_cidr_block" {
  description = "The CIDR block of the VPC"
  value       = local.vpc_cidr
}

output "vpc_public_subnets" {
  description = "List of IDs of public subnets"
  value       = try(module.network[0].public_subnets, null)
}

output "vpc_public_subnets_cidr_blocks" {
  description = "List of CIDR blocks of public subnets"
  value       = try(module.network[0].public_subnets_cidr_blocks, null)
}

output "vpc_private_subnets" {
  description = "List of IDs of private subnets"
  value       = try(module.network[0].private_subnets, null)
}

output "vpc_private_subnets_cidr_blocks" {
  description = "List of CIDR blocks of private subnets"
  value       = try(module.network[0].private_subnets_cidr_blocks, null)
}

output "vpc_database_subnets" {
  description = "List of IDs of database subnets"
  value       = try(module.network[0].database_subnets, null)
}

output "vpc_database_subnets_cidr_blocks" {
  description = "List of CIDR blocks of the database subnets"
  value       = try(module.acm[0].database_subnets_cidr_blocks, null)
}


################################################################################
# DNS
################################################################################

output "public_route53_zone_id" {
  description = "Zone ID of the public Route53 zone"
  value       = local.public_zone_id
}

output "public_route53_zone_arn" {
  description = "Zone ARN of the public Route53 zone"
  value       = local.public_zone_arn
}

output "public_route53_zone_name_servers" {
  description = "Name servers of Route53 zone"
  value       = local.public_zone_name_servers
}

output "private_route53_zone_id" {
  description = "Zone ID of the private Route53 zone"
  value       = local.private_zone_id
}

output "private_route53_zone_arn" {
  description = "Zone ARN of the private Route53 zone"
  value       = local.private_zone_arn
}


################################################################################
# ACM
################################################################################

output "acm_certificate_arn" {
  description = "ARN of the ACM certificate"
  value       = try(module.acm[0].acm_certificate_arn, null)
}


################################################################################
# Storage
################################################################################

output "s3_bucket_id" {
  description = "Name of the S3 bucket"
  value       = local.s3_bucket_id
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
  value       = local.eks_cluster_name
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
  value       = local.app_role_arn
}

output "genai_role_arn" {
  description = "ARN of the IAM role assumed by the DataRobot app IRSA when accessing Amazon Bedrock AI Foundational Models"
  value       = try(module.genai_identity[0].arn, null)
}


################################################################################
# PostgreSQL
################################################################################

output "postgres_endpoint" {
  description = "RDS postgres endpoint"
  value       = try(module.postgres[0].endpoint, null)
}

output "postgres_password" {
  description = "RDS postgres master password"
  value       = try(module.postgres[0].password, null)
  sensitive   = true
}


################################################################################
# Redis
################################################################################

output "redis_endpoint" {
  description = "Elasticache redis endpoint"
  value       = try(module.redis[0].endpoint, null)
}

output "redis_password" {
  description = "Elasticache redis auth token"
  value       = try(module.redis[0].password, null)
  sensitive   = true
}


################################################################################
# MongoDB
################################################################################

output "mongodb_endpoint" {
  description = "MongoDB endpoint"
  value       = try(module.mongodb[0].endpoint, null)
}

output "mongodb_password" {
  description = "MongoDB admin password"
  value       = try(module.mongodb[0].password, null)
  sensitive   = true
}

################################################################################
# RabbitMQ
################################################################################

output "rabbitmq_endpoint" {
  description = "RabbitMQ AMQP(S) endpoint"
  value       = try(module.rabbitmq[0].endpoint, null)
}

output "rabbitmq_password" {
  description = "RabbitMQ broker password"
  value       = try(module.rabbitmq[0].password, null)
  sensitive   = true
}


################################################################################
# ingress-nginx
################################################################################

output "ingress_vpce_service_id" {
  description = "Ingress VPCE service ID"
  value       = try(module.ingress_nginx[0].vpce_service_id, null)
}
