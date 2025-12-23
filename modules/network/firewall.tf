# AWS Network Firewall Architecture
# ===================================
# When network_firewall is enabled, this module manages all public networking
# resources to ensure all traffic flows through the firewall endpoint:
#
# Resources Created:
# - Internet Gateway
# - Public Subnets (for ALB, NAT Gateways)
# - Public Route Tables (one per AZ)
# - NAT Gateways (one per AZ)
# - Elastic IPs (for NAT Gateways)
# - Firewall Subnets
# - Firewall Route Table
# - IGW Route Table (for ingress routing)
#
# Traffic Flow:
# 1. Inbound (Internet -> Public Resources):
#    Internet -> IGW -> Firewall Endpoint -> Public Subnets
# 2. Outbound (Private Resources -> Internet):
#    Private Subnets -> NAT Gateway (in Public Subnet) ->
#    Firewall Endpoint -> IGW -> Internet
#
# This prevents conflicts with the terraform-aws-modules/vpc module's default route creation for public_subnets.


locals {
  firewall_endpoint_ids = var.network_firewall ? {
    for ss in module.network_firewall[0].status[0].sync_states :
    ss.availability_zone => ss.attachment[0].endpoint_id
  } : {}
}


################################################################################
# Internet Gateway
################################################################################
resource "aws_internet_gateway" "this" {
  count = var.network_firewall ? 1 : 0

  vpc_id = module.vpc.vpc_id

  tags = merge(
    var.tags,
    {
      Name = var.name
    }
  )
}

resource "aws_route_table" "igw" {
  count = var.network_firewall ? 1 : 0

  vpc_id = module.vpc.vpc_id

  tags = merge(
    var.tags,
    {
      Name = "${var.name}-igw"
    }
  )
}

resource "aws_route_table_association" "igw" {
  count = var.network_firewall ? 1 : 0

  route_table_id = aws_route_table.igw[0].id
  gateway_id     = aws_internet_gateway.this[0].id
}

# Inbound traffic bound for the public subnets gets routed through the firewall
resource "aws_route" "igw_firewall" {
  count = var.network_firewall ? length(local.azs) : 0

  route_table_id         = aws_route_table.igw[0].id
  destination_cidr_block = aws_subnet.public[count.index].cidr_block
  vpc_endpoint_id        = local.firewall_endpoint_ids[local.azs[count.index]]
}


################################################################################
# Firewall
################################################################################
resource "aws_subnet" "firewall" {
  count = var.network_firewall ? length(local.azs) : 0

  vpc_id            = module.vpc.vpc_id
  cidr_block        = local.firewall_subnet_cidrs[count.index]
  availability_zone = local.azs[count.index]
  tags = merge(
    var.tags,
    {
      Name = "${var.name}-firewall-${local.azs[count.index]}"
    }
  )
}

resource "aws_route_table" "firewall" {
  count = var.network_firewall ? 1 : 0

  vpc_id = module.vpc.vpc_id

  tags = merge(
    var.tags,
    {
      Name = "${var.name}-firewall"
    }
  )
}

resource "aws_route_table_association" "firewall" {
  count = var.network_firewall ? length(local.azs) : 0

  subnet_id      = aws_subnet.firewall[count.index].id
  route_table_id = aws_route_table.firewall[0].id
}

# Outbound traffic from firewall subnets is routed through the IGW
resource "aws_route" "firewall_igw" {
  count = var.network_firewall ? 1 : 0

  route_table_id         = aws_route_table.firewall[0].id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.this[0].id
}

module "network_firewall" {
  source = "terraform-aws-modules/network-firewall/aws"
  count  = var.network_firewall ? 1 : 0

  name = var.name

  vpc_id         = module.vpc.vpc_id
  subnet_mapping = { for subnet in aws_subnet.firewall : subnet.availability_zone => { subnet_id = subnet.id } }

  delete_protection        = var.network_firewall_delete_protection
  subnet_change_protection = var.network_firewall_subnet_change_protection

  create_logging_configuration = var.network_firewall_create_logging_configuration
  logging_configuration_destination_config = [
    {
      log_type             = "ALERT"
      log_destination_type = "CloudWatchLogs"
      log_destination = {
        logGroup = aws_cloudwatch_log_group.network_firewall_alert[0].name
      }
    },
    {
      log_type             = "FLOW"
      log_destination_type = "CloudWatchLogs"
      log_destination = {
        logGroup = aws_cloudwatch_log_group.network_firewall_flow[0].name
      }
    }
  ]

  policy_name                               = var.name
  policy_stateless_default_actions          = var.network_firewall_policy_stateless_default_actions
  policy_stateless_fragment_default_actions = var.network_firewall_policy_stateless_fragment_default_actions
  policy_stateless_rule_group_reference     = var.network_firewall_policy_stateless_rule_group_reference
  policy_stateful_rule_group_reference      = var.network_firewall_policy_stateful_rule_group_reference

  tags = var.tags
}


################################################################################
# Public Subnets
################################################################################
resource "aws_subnet" "public" {
  count = var.network_firewall ? length(local.azs) : 0

  vpc_id            = module.vpc.vpc_id
  cidr_block        = local.public_subnet_cidrs[count.index]
  availability_zone = local.azs[count.index]

  tags = merge(
    var.tags,
    {
      Name                     = "${var.name}-public-${local.azs[count.index]}"
      "kubernetes.io/role/elb" = 1
    }
  )
}

resource "aws_route_table" "public" {
  count = var.network_firewall ? length(local.azs) : 0

  vpc_id = module.vpc.vpc_id

  tags = merge(
    var.tags,
    {
      Name = "${var.name}-public-${local.azs[count.index]}"
    }
  )
}

resource "aws_route_table_association" "public" {
  count = var.network_firewall ? length(local.azs) : 0

  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public[count.index].id
}

# Outbound traffic from public subnets routed through firewall endpoint
resource "aws_route" "public_firewall" {
  count = var.network_firewall ? length(local.azs) : 0

  route_table_id         = aws_route_table.public[count.index].id
  destination_cidr_block = "0.0.0.0/0"
  vpc_endpoint_id        = local.firewall_endpoint_ids[local.azs[count.index]]
}

resource "aws_eip" "nat" {
  count = var.network_firewall ? length(local.azs) : 0

  domain = "vpc"

  tags = merge(
    var.tags,
    {
      Name = "${var.name}-nat-${local.azs[count.index]}"
    }
  )

  depends_on = [aws_internet_gateway.this]
}

resource "aws_nat_gateway" "this" {
  count = var.network_firewall ? length(local.azs) : 0

  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.public[count.index].id

  tags = merge(
    var.tags,
    {
      Name = "${var.name}-${local.azs[count.index]}"
    }
  )

  depends_on = [aws_internet_gateway.this]
}


################################################################################
# Private Subnets
################################################################################
# Outbound traffic from private subnets is routed through the NAT Gateway
resource "aws_route" "private_nat_gateway" {
  count = var.network_firewall ? length(local.azs) : 0

  route_table_id         = module.vpc.private_route_table_ids[count.index]
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.this[count.index].id
}


################################################################################
# Logging
################################################################################
resource "aws_cloudwatch_log_group" "network_firewall_alert" {
  count = var.network_firewall && var.network_firewall_create_logging_configuration ? 1 : 0

  name              = "/aws/network-firewall/${var.name}/alert"
  retention_in_days = var.network_firewall_alert_log_retention

  tags = var.tags
}

resource "aws_cloudwatch_log_group" "network_firewall_flow" {
  count = var.network_firewall && var.network_firewall_create_logging_configuration ? 1 : 0

  name              = "/aws/network-firewall/${var.name}/flow"
  retention_in_days = var.network_firewall_flow_log_retention

  tags = var.tags
}
