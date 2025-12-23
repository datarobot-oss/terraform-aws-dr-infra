module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 6.0"

  name = var.name
  cidr = var.network_address_space

  azs             = local.azs
  private_subnets = local.private_subnet_cidrs
  # When using network firewall, manage public subnets manually to control routing
  public_subnets = var.network_firewall ? [] : local.public_subnet_cidrs
  intra_subnets  = local.intra_subnet_cidrs

  enable_nat_gateway     = !var.network_firewall
  one_nat_gateway_per_az = true

  public_subnet_tags = {
    "kubernetes.io/role/elb" = 1
  }
  private_subnet_tags = {
    "kubernetes.io/role/internal-elb" = 1
  }

  tags = var.tags
}

module "flow_log" {
  source = "terraform-aws-modules/vpc/aws//modules/flow-log"
  count  = var.enable_vpc_flow_logs ? 1 : 0

  name   = var.name
  vpc_id = module.vpc.vpc_id

  cloudwatch_log_group_use_name_prefix   = false
  cloudwatch_log_group_retention_in_days = var.vpc_flow_log_retention

  tags = var.tags
}
