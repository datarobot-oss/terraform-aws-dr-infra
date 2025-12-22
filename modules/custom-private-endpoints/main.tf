resource "aws_security_group" "this" {
  name_prefix = "${var.name}-endpoint-sg"
  vpc_id      = var.vpc_id
  ingress {
    description = "Allow All Traffic From VPC"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [var.vpc_cidr]
  }
  egress {
    description = "Allow All Egress Traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  lifecycle {
    create_before_destroy = true
  }
  tags = var.tags
}

resource "aws_vpc_endpoint" "this" {
  vpc_id            = var.vpc_id
  service_name      = var.endpoint_config.service_name
  vpc_endpoint_type = "Interface"
  subnet_ids        = var.subnets
  security_group_ids = [
    aws_security_group.this.id
  ]
  tags = var.tags
}

resource "aws_route53_zone" "this" {
  count = var.endpoint_config.private_dns_zone != "" ? 1 : 0
  name  = var.endpoint_config.private_dns_zone
  vpc {
    vpc_id = var.vpc_id
  }
  tags = var.tags
}

resource "aws_route53_record" "this" {
  count   = var.endpoint_config.private_dns_name != "" && var.endpoint_config.private_dns_zone != "" ? 1 : 0
  name    = "${var.endpoint_config.private_dns_name}.${var.endpoint_config.private_dns_zone}"
  zone_id = aws_route53_zone.this[0].id
  type    = "CNAME"
  ttl     = 60
  records = [aws_vpc_endpoint.this.dns_entry[0].dns_name]
}

locals {
  target_fqdn    = var.endpoint_config.private_dns_name != "" ? aws_route53_record.this[0].name : aws_vpc_endpoint.this.dns_entry[0].dns_name
  raw_short_name = var.endpoint_config.private_dns_name != "" ? var.endpoint_config.private_dns_name : element(split(".", var.endpoint_config.service_name), length(split(".", var.endpoint_config.service_name)) - 1)
  short_name     = lower(replace(local.raw_short_name, "[^a-zA-Z0-9-]", "-"))
}

resource "kubectl_manifest" "network_policy" {
  count     = var.cilium ? 1 : 0
  yaml_body = <<YAML
apiVersion: "cilium.io/v2"
kind: CiliumClusterwideNetworkPolicy
metadata:
  name: "dr-core-to-${local.short_name}"
  labels:
    datarobot-netpol: custom-endpoint
spec:
  endpointSelector:
    matchLabels:
      "k8s:io.kubernetes.pod.namespace": dr-core
  egress:
  - toFQDNs:
    - matchName: "${local.target_fqdn}"
  - toEndpoints:
    - matchLabels:
        "k8s:io.kubernetes.pod.namespace": kube-system
        "k8s:k8s-app": kube-dns
    toPorts:
    - ports:
      - port: "53"
        protocol: ANY
      rules:
        dns:
        - matchPattern: "*"
YAML
}
