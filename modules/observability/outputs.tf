output "observability_prometheus_endpoint" {
  description = "The write endpoint of the Prometheus workspace"
  value       = aws_prometheus_workspace.observability_prom_workspace.prometheus_endpoint
}

output "observability_grafana_endpoint" {
  description = "The endpoint of the Grafana workspace"
  value       = aws_grafana_workspace.grafana.endpoint
}
