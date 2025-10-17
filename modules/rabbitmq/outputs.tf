output "endpoint" {
  description = "AMQP(S) endpoint"
  value       = aws_mq_broker.this.instances[0].endpoints[0]
}

output "password" {
  description = "RabbitMQ broker password"
  value       = random_password.rabbitmq.result
  sensitive   = true
}
