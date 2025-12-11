output "load_balancer_arn" {
  value       = data.aws_lb.ingress.arn
  description = "The ARN of the ingress load balancer"
}
