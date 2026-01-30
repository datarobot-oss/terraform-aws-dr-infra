output "endpoint" {
  description = "ElastiCache redis endpoint"
  value       = module.redis.replication_group_primary_endpoint_address
}

output "password" {
  description = "ElastiCache redis auth token"
  value       = random_password.redis.result
  sensitive   = true
}
