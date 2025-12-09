resource "aws_vpc_endpoint_service" "ingress" {
  acceptance_required        = false
  network_load_balancer_arns = var.ingress_lb_arns
  allowed_principals         = var.vpce_service_allowed_principals
  private_dns_name           = var.vpce_service_private_dns_name

  tags = merge(var.tags, { Name = "${var.eks_cluster_name}-ingress-vpce-service" })
}

resource "aws_route53_record" "txt_private_confirmation_record" {
  zone_id = var.route53_zone_id
  name    = aws_vpc_endpoint_service.ingress.private_dns_name_configuration[0].name
  type    = aws_vpc_endpoint_service.ingress.private_dns_name_configuration[0].type
  records = [aws_vpc_endpoint_service.ingress.private_dns_name_configuration[0].value]
  ttl     = 300
}
