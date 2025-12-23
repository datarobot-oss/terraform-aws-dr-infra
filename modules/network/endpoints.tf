data "aws_region" "current" {}

module "endpoints" {
  source  = "terraform-aws-modules/vpc/aws//modules/vpc-endpoints"
  version = "~> 6.0"
  count   = length(var.interface_endpoints) > 0 ? 1 : 0

  vpc_id                     = module.vpc.vpc_id
  create_security_group      = true
  security_group_name        = "${var.name}-endpoints"
  security_group_description = "VPC endpoint default security group"
  security_group_rules = {
    ingress_https = {
      description = "HTTPS from VPC"
      cidr_blocks = [module.vpc.vpc_cidr_block]
    }
  }

  endpoints = { for endpoint_service in var.interface_endpoints :
    endpoint_service => {
      service             = endpoint_service
      subnet_ids          = module.vpc.private_subnets
      private_dns_enabled = endpoint_service != "s3" || var.s3_private_dns_enabled
      dns_options = {
        private_dns_only_for_inbound_resolver_endpoint = false
      }
    }
  }

  tags = var.tags
}

# manually create S3 endpoint CNAME when private DNS is disabled
resource "aws_route53_record" "s3_endpoint_cname" {
  count = contains(var.interface_endpoints, "s3") && !var.s3_private_dns_enabled ? 1 : 0

  zone_id = var.zone_id
  name    = var.fips_enabled ? "s3-fips.${data.aws_region.current.region}.amazonaws.com" : "s3.${data.aws_region.current.region}.amazonaws.com"
  type    = "CNAME"
  records = [module.endpoints[0].endpoints["s3"].dns_entry[0].dns_name]
  ttl     = 300
}
