output "endpoint" {
  description = "MongoDB Atlas private endpoint SRV connection string"
  value       = mongodbatlas_cluster.this.connection_strings[0].private_endpoint[0].srv_connection_string
}

output "password" {
  description = "MongoDB Atlas admin password"
  value       = random_password.admin.result
  sensitive   = true
}
