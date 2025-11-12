resource "aws_vpc_endpoint_service" "ingress" {

  acceptance_required        = false
  network_load_balancer_arns = var.ingress_lb_arns
  allowed_principals         = var.vpce_service_allowed_principals
  private_dns_name           = var.vpce_service_private_dns_name

  tags = merge(var.tags, { Name = "${var.eks_cluster_name}-ingress-vpce-service" })
}
