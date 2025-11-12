output "load_balancer_arn" {
  value       = try(data.aws_lb.ingress[0].arn, null)
  description = "The ARN of the ingress load balancer"
}
