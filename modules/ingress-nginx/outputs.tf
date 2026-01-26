output "load_balancer_arn" {
  description = "The ARN of the ingress load balancer"
  value       = data.aws_lb.ingress.arn
}

output "load_balancer_dns_name" {
  description = "The DNS name of the ingress load balancer"
  value       = data.aws_lb.ingress.dns_name
}
