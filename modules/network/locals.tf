data "aws_availability_zones" "available" {
  state = "available"
  filter {
    name   = "opt-in-status"
    values = ["opt-in-not-required"]
  }
}

locals {
  azs = slice(data.aws_availability_zones.available.names, 0, var.availability_zones)

  private_subnet_cidrs  = [for k, v in local.azs : cidrsubnet(var.network_address_space, 4, k)]      # /20 EKS nodes
  intra_subnet_cidrs    = [for k, v in local.azs : cidrsubnet(var.network_address_space, 8, k + 48)] # /24 PCS
  public_subnet_cidrs   = [for k, v in local.azs : cidrsubnet(var.network_address_space, 8, k + 52)] # /24 ALB + NAT
  firewall_subnet_cidrs = [for k, v in local.azs : cidrsubnet(var.network_address_space, 8, k + 56)] # /24 Firewall
}
