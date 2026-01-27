output "endpoint" {
  description = "The hostname of the RDS instance"
  value       = module.postgres.db_instance_address
}

output "password" {
  description = "RDS postgres master password"
  value       = random_password.postgres.result
  sensitive   = true
}

output "route53_endpoint" {
  description = "Route53 endpoint for the RDS instance"
  value       = aws_route53_record.this.fqdn
}
