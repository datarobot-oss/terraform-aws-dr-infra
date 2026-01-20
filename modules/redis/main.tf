resource "random_password" "redis" {
  length      = var.password_constraints.length
  special     = var.password_constraints.special
  min_lower   = var.password_constraints.min_lower
  min_upper   = var.password_constraints.min_upper
  min_numeric = var.password_constraints.min_numeric
}

module "redis" {
  source  = "terraform-aws-modules/elasticache/aws"
  version = "~> 1.0"

  replication_group_id    = var.name
  multi_az_enabled        = var.multi_az
  num_node_groups         = 1
  replicas_per_node_group = 2

  auth_token               = random_password.redis.result
  engine_version           = var.redis_engine_version
  node_type                = var.redis_node_type
  snapshot_retention_limit = var.redis_snapshot_retention
  apply_immediately        = true

  vpc_id            = var.vpc_id
  subnet_ids        = var.subnets
  subnet_group_name = var.subnet_group_name

  security_group_rules = {
    ingress_vpc = {
      description = "VPC redis traffic"
      cidr_ipv4   = var.vpc_cidr
    }
  }
  security_group_tags = {
    Name = "${var.name}-redis"
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
