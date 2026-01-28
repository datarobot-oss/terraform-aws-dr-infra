output "endpoint" {
  description = "The hostname of the RDS instance"
  value       = module.postgres.db_instance_address
}

output "route53_endpoint" {
  description = "Route53 endpoint for the RDS instance"
  value       = try(aws_route53_record.this[0].fqdn, null)
}

output "password" {
  description = "RDS postgres master password"
  value       = random_password.postgres.result
  sensitive   = true
}
