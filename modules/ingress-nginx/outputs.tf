output "vpce_service_id" {
  description = "VPCE service ID"
  value       = try(aws_vpc_endpoint_service.ingress[0].id, null)
}
