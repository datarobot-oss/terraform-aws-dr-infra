resource "random_password" "redis" {
  length           = 32
  override_special = "!&#$^<>-"
  min_lower        = 1
  min_upper        = 1
  min_numeric      = 1
  min_special      = 1
}

module "redis" {
  source  = "terraform-aws-modules/elasticache/aws"
  version = "~> 1.0"

  replication_group_id    = var.name
  multi_az_enabled        = var.multi_az
  num_node_groups         = 1
  replicas_per_node_group = 2

  auth_token        = random_password.redis.result
  engine_version    = var.redis_engine_version
  node_type         = var.redis_node_type
  apply_immediately = true

  vpc_id     = var.vpc_id
  subnet_ids = var.subnets

  security_group_rules = {
    ingress_vpc = {
      description = "VPC redis traffic"
      cidr_ipv4   = var.vpc_cidr
    }
  }

  create_parameter_group = true
  parameter_group_family = "redis7"
  parameters = [
    {
      name  = "latency-tracking"
      value = "yes"
    }
  ]

  tags = var.tags
}

resource "aws_secretsmanager_secret" "redis_password" {
  name                    = "${var.name}-redis-password"
  recovery_window_in_days = 0
  tags                    = var.tags
}

resource "aws_secretsmanager_secret_version" "redis_password" {
  secret_id     = aws_secretsmanager_secret.redis_password.id
  secret_string = random_password.redis.result
}
