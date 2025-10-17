resource "random_password" "rabbitmq" {
  length      = 32
  special     = false
  min_lower   = 1
  min_upper   = 1
  min_numeric = 1
}

locals {
  port      = 5671
  http_port = 15671
}

module "security_group" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "~> 5.0"

  name   = "${var.name}-rabbitmq"
  vpc_id = var.vpc_id

  ingress_with_cidr_blocks = [
    {
      from_port   = local.port
      to_port     = local.port
      protocol    = "tcp"
      description = "VPC rabbitmq access"
      cidr_blocks = var.vpc_cidr
    },
    {
      from_port   = local.http_port
      to_port     = local.http_port
      protocol    = "tcp"
      description = "VPC rabbitmq http access"
      cidr_blocks = var.vpc_cidr
    }
  ]

  tags = var.tags
}

resource "aws_mq_configuration" "this" {
  name           = "${var.name}-rabbitmq"
  description    = "${var.name}-rabbitmq"
  engine_type    = "RabbitMQ"
  engine_version = var.engine_version

  data = <<DATA
# Setting RabbitMQ delivery acknowledgement timeout to 24h as required by the monolith
consumer_timeout = 86400000
DATA
}

resource "aws_mq_broker" "this" {
  broker_name                = "${var.name}-rabbitmq"
  engine_type                = "RabbitMQ"
  engine_version             = var.engine_version
  storage_type               = "ebs"
  host_instance_type         = var.host_instance_type
  authentication_strategy    = var.authentication_strategy
  deployment_mode            = var.multi_az ? "CLUSTER_MULTI_AZ" : "SINGLE_INSTANCE"
  apply_immediately          = true
  auto_minor_version_upgrade = var.auto_minor_version_upgrade
  publicly_accessible        = false
  security_groups            = [module.security_group.security_group_id]
  subnet_ids                 = var.subnets
  tags                       = var.tags

  user {
    username = var.username
    password = random_password.rabbitmq.result
  }

  configuration {
    id       = aws_mq_configuration.this.id
    revision = aws_mq_configuration.this.latest_revision
  }

  logs {
    general = var.log
  }

}

resource "aws_cloudwatch_log_group" "this" {
  for_each = var.log ? toset(["channel", "connection", "general"]) : []

  name              = "/aws/amazonmq/broker/${aws_mq_broker.this.id}/${each.value}"
  retention_in_days = var.log_retention
  tags              = var.tags
}
