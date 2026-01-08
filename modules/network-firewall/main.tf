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
  firewall_endpoint_ids = { for ss in module.network_firewall.status[0].sync_states :
    ss.availability_zone => ss.attachment[0].endpoint_id
  }
}


################################################################################
# Internet Gateway
################################################################################
resource "aws_internet_gateway" "this" {
  vpc_id = var.vpc_id

  tags = merge(
    var.tags,
    {
      Name = var.name
    }
  )
}

resource "aws_route_table" "igw" {
  vpc_id = var.vpc_id

  tags = merge(
    var.tags,
    {
      Name = "${var.name}-igw"
    }
  )
}

resource "aws_route_table_association" "igw" {
  route_table_id = aws_route_table.igw.id
  gateway_id     = aws_internet_gateway.this.id
}

# Inbound traffic bound for the public subnets gets routed through the firewall
resource "aws_route" "igw_firewall" {
  count = length(var.azs)

  route_table_id         = aws_route_table.igw.id
  destination_cidr_block = aws_subnet.public[count.index].cidr_block
  vpc_endpoint_id        = local.firewall_endpoint_ids[var.azs[count.index]]
}


################################################################################
# Firewall
################################################################################
resource "aws_subnet" "firewall" {
  count = length(var.azs)

  vpc_id            = var.vpc_id
  cidr_block        = var.firewall_subnet_cidrs[count.index]
  availability_zone = var.azs[count.index]
  tags = merge(
    var.tags,
    {
      Name = "${var.name}-firewall-${var.azs[count.index]}"
    }
  )
}

resource "aws_route_table" "firewall" {
  vpc_id = var.vpc_id

  tags = merge(
    var.tags,
    {
      Name = "${var.name}-firewall"
    }
  )
}

resource "aws_route_table_association" "firewall" {
  count = length(var.azs)

  subnet_id      = aws_subnet.firewall[count.index].id
  route_table_id = aws_route_table.firewall.id
}

# Outbound traffic from firewall subnets is routed through the IGW
resource "aws_route" "firewall_igw" {
  route_table_id         = aws_route_table.firewall.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.this.id
}

module "network_firewall" {
  source = "terraform-aws-modules/network-firewall/aws"

  name = var.name

  vpc_id         = var.vpc_id
  subnet_mapping = { for subnet in aws_subnet.firewall : subnet.availability_zone => { subnet_id = subnet.id } }

  delete_protection        = var.delete_protection
  subnet_change_protection = var.subnet_change_protection

  create_logging_configuration = var.create_logging_configuration
  logging_configuration_destination_config = [
    {
      log_type             = "ALERT"
      log_destination_type = "CloudWatchLogs"
      log_destination = {
        logGroup = try(aws_cloudwatch_log_group.network_firewall_alert[0].name, null)
      }
    },
    {
      log_type             = "FLOW"
      log_destination_type = "CloudWatchLogs"
      log_destination = {
        logGroup = try(aws_cloudwatch_log_group.network_firewall_flow[0].name, null)
      }
    }
  ]

  policy_name                               = var.name
  policy_stateless_default_actions          = var.policy_stateless_default_actions
  policy_stateless_fragment_default_actions = var.policy_stateless_fragment_default_actions
  policy_stateless_rule_group_reference     = var.policy_stateless_rule_group_reference
  policy_stateful_rule_group_reference      = var.policy_stateful_rule_group_reference

  tags = var.tags
}


################################################################################
# Public Subnets
################################################################################
resource "aws_subnet" "public" {
  count = length(var.azs)

  vpc_id            = var.vpc_id
  cidr_block        = var.public_subnet_cidrs[count.index]
  availability_zone = var.azs[count.index]

  tags = merge(
    var.tags,
    {
      Name                     = "${var.name}-public-${var.azs[count.index]}"
      "kubernetes.io/role/elb" = 1
    }
  )
}

resource "aws_route_table" "public" {
  count = length(var.azs)

  vpc_id = var.vpc_id

  tags = merge(
    var.tags,
    {
      Name = "${var.name}-public-${var.azs[count.index]}"
    }
  )
}

resource "aws_route_table_association" "public" {
  count = length(var.azs)

  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public[count.index].id
}

# Outbound traffic from public subnets routed through firewall endpoint
resource "aws_route" "public_firewall" {
  count = length(var.azs)

  route_table_id         = aws_route_table.public[count.index].id
  destination_cidr_block = "0.0.0.0/0"
  vpc_endpoint_id        = local.firewall_endpoint_ids[var.azs[count.index]]
}

resource "aws_eip" "nat" {
  count = length(var.azs)

  domain = "vpc"

  tags = merge(
    var.tags,
    {
      Name = "${var.name}-nat-${var.azs[count.index]}"
    }
  )

  depends_on = [aws_internet_gateway.this]
}

resource "aws_nat_gateway" "this" {
  count = length(var.azs)

  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.public[count.index].id

  tags = merge(
    var.tags,
    {
      Name = "${var.name}-${var.azs[count.index]}"
    }
  )

  depends_on = [aws_internet_gateway.this]
}


################################################################################
# Private Subnets
################################################################################
# Outbound traffic from private subnets is routed through the NAT Gateway
resource "aws_route" "private_nat_gateway" {
  count = length(var.azs)

  route_table_id         = var.private_route_table_ids[count.index]
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.this[count.index].id
}


################################################################################
# Logging
################################################################################
resource "aws_cloudwatch_log_group" "network_firewall_alert" {
  count = var.create_logging_configuration ? 1 : 0

  name              = "/aws/network-firewall/${var.name}/alert"
  retention_in_days = var.alert_log_retention

  tags = var.tags
}

resource "aws_cloudwatch_log_group" "network_firewall_flow" {
  count = var.create_logging_configuration ? 1 : 0

  name              = "/aws/network-firewall/${var.name}/flow"
  retention_in_days = var.flow_log_retention

  tags = var.tags
}
