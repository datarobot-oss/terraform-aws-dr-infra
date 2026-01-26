resource "random_password" "postgres" {
  length      = var.password_constraints.length
  special     = var.password_constraints.special
  min_lower   = var.password_constraints.min_lower
  min_upper   = var.password_constraints.min_upper
  min_numeric = var.password_constraints.min_numeric
}

module "security_group" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "~> 5.0"

  name   = "${var.name}-postgres"
  vpc_id = var.vpc_id

  ingress_rules       = ["postgresql-tcp"]
  ingress_cidr_blocks = var.ingress_cidr_blocks

  tags = var.tags
}

module "postgres" {
  source  = "terraform-aws-modules/rds/aws"
  version = "~> 6.0"

  identifier = var.name

  multi_az                        = var.multi_az
  subnet_ids                      = var.subnets
  create_db_subnet_group          = true
  db_subnet_group_name            = var.subnet_group_name
  db_subnet_group_use_name_prefix = var.subnet_group_use_name_prefix
  vpc_security_group_ids          = [module.security_group.security_group_id]

  engine               = "postgres"
  engine_version       = var.postgres_engine_version
  family               = "postgres13"
  major_engine_version = var.postgres_engine_version
  apply_immediately    = true

  instance_class        = var.postgres_instance_class
  allocated_storage     = var.postgres_allocated_storage
  max_allocated_storage = var.postgres_max_allocated_storage
  port                  = 5432

  create_cloudwatch_log_group     = true
  enabled_cloudwatch_logs_exports = ["postgresql", "upgrade"]

  backup_retention_period = var.postgres_backup_retention_period
  skip_final_snapshot     = true
  deletion_protection     = var.postgres_deletion_protection
  storage_encrypted       = true

  db_name                     = "postgres"
  username                    = "postgres"
  password                    = random_password.postgres.result
  manage_master_user_password = false

  parameters = [
    {
      name  = "password_encryption"
      value = "scram-sha-256"
    }
  ]

  tags = var.tags
}

resource "aws_route53_record" "this" {
  zone_id = var.route_53_zone_id
  name    = "${var.name}-pgsql"
  type    = "CNAME"
  ttl     = "300"
  records = [module.postgres.db_instance_endpoint]
}
