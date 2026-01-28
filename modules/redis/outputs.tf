output "endpoint" {
  description = "ElastiCache redis endpoint"
  value       = module.redis.replication_group_primary_endpoint_address
}

output "route53_endpoint" {
  description = "Route53 endpoint for the Redis instance"
  value       = try(aws_route53_record.this[0].fqdn, null)
}

output "password" {
  description = "ElastiCache redis auth token"
  value       = random_password.redis.result
  sensitive   = true
}
