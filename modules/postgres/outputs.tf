output "endpoint" {
  description = "The hostname of the RDS instance"
  value       = module.postgres.db_instance_address
}

output "password" {
  description = "RDS postgres master password"
  value       = data.aws_secretsmanager_secret_version.postgres_password.secret_string
  sensitive   = true
}
