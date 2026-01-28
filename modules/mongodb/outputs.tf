output "endpoint" {
  description = "MongoDB Atlas private endpoint SRV connection string"
  value       = length(local.connection_strings) > 0 ? local.connection_strings[0] : ""
}

output "route53_endpoint" {
  description = "Route53 endpoint for the MongoDB instance"
  value       = try(aws_route53_record.this[0].fqdn, null)
}

output "password" {
  description = "MongoDB Atlas admin password"
  value       = random_password.admin.result
  sensitive   = true
}
