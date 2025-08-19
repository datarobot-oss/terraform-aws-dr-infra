output "endpoint" {
  description = "RDS postgres endpoint"
  value       = module.postgres.db_instance_endpoint
}

output "password" {
  description = "RDS postgres master password"
  value       = data.aws_secretsmanager_secret_version.postgres_password.secret_string
  sensitive   = true
}
