data "aws_region" "this" {}
data "aws_regions" "current" {}

locals {
  region      = upper(replace(data.aws_region.this.region, "-", "_"))
  copy_region = upper(replace(tolist(setsubtract(data.aws_regions.current.names, [data.aws_region.this.region]))[0], "-", "_"))
}

resource "mongodbatlas_project" "this" {
  org_id = var.atlas_org_id
  name   = var.name
}

resource "mongodbatlas_project_ip_access_list" "this" {
  project_id = mongodbatlas_project.this.id
  cidr_block = var.vpc_cidr
  comment    = "cidr block for AWS VPC"
}

resource "mongodbatlas_privatelink_endpoint" "this" {
  project_id    = mongodbatlas_project.this.id
  provider_name = "AWS"
  region        = local.region
}

resource "mongodbatlas_privatelink_endpoint_service" "this" {
  project_id          = mongodbatlas_privatelink_endpoint.this.project_id
  endpoint_service_id = aws_vpc_endpoint.this.id
  private_link_id     = mongodbatlas_privatelink_endpoint.this.id
  provider_name       = "AWS"
}

resource "aws_vpc_endpoint" "this" {
  vpc_id             = var.vpc_id
  service_name       = mongodbatlas_privatelink_endpoint.this.endpoint_service_name
  vpc_endpoint_type  = "Interface"
  subnet_ids         = var.subnets
  security_group_ids = [aws_security_group.this.id]
  tags               = merge(var.tags, { Name = "${var.name}-mongodb" })
}

resource "mongodbatlas_advanced_cluster" "this" {
  project_id   = mongodbatlas_project.this.id
  name         = var.name
  cluster_type = "REPLICASET"

  mongo_db_major_version         = var.mongodb_version
  backup_enabled                 = true
  pit_enabled                    = true
  termination_protection_enabled = var.termination_protection_enabled

  replication_specs = [{
    region_configs = [{
      provider_name = "AWS"
      region_name   = local.region
      priority      = 7

      electable_specs = {
        instance_size = var.atlas_instance_type
        disk_size_gb  = var.atlas_disk_size
        node_count    = 3
      }

      auto_scaling = {
        disk_gb_enabled = var.atlas_auto_scaling_disk_gb_enabled
      }
    }]
  }]

  advanced_configuration = {
    javascript_enabled           = true
    minimum_enabled_tls_protocol = "TLS1_2"
  }

  lifecycle {
    ignore_changes = [replication_specs[0].region_configs[0].electable_specs.disk_size_gb]
  }

  depends_on = [mongodbatlas_privatelink_endpoint_service.this]
}

resource "mongodbatlas_cloud_backup_schedule" "aws_mongo_atlas_automated_cloud_backup" {
  project_id   = mongodbatlas_project.this.id
  cluster_name = mongodbatlas_advanced_cluster.this.name

  policy_item_hourly {
    frequency_interval = 6 #accepted values = 1, 2, 4, 6, 8, 12 -> every n hours
    retention_unit     = "days"
    retention_value    = 7
  }
  policy_item_daily {
    frequency_interval = 1 #accepted values = 1 -> every 1 day
    retention_unit     = "days"
    retention_value    = 30
  }
  policy_item_weekly {
    frequency_interval = 6 # accepted values = 1 to 7 -> every 1=Monday,2=Tuesday,3=Wednesday,4=Thursday,5=Friday,6=Saturday,7=Sunday day of the week
    retention_unit     = "days"
    retention_value    = 30
  }
  policy_item_monthly {
    frequency_interval = 1 # accepted values = 1 to 28 -> 1 to 28 every nth day of the month
    # accepted values = 40 -> every last day of the month
    retention_unit  = "months"
    retention_value = 1
  }
  copy_settings {
    cloud_provider = "AWS"
    frequencies = [
      "HOURLY",
      "DAILY",
      "WEEKLY",
      "MONTHLY",
      "ON_DEMAND"
    ]
    region_name        = local.copy_region
    zone_id            = mongodbatlas_advanced_cluster.this.replication_specs[0].zone_id
    should_copy_oplogs = true
  }
}

# https://www.mongodb.com/docs/atlas/security-private-endpoint/#port-ranges-used-for-private-endpoints
resource "aws_security_group" "this" {
  name        = "${var.name}-mongodb"
  description = "Allow access to mongodb atlas private endpoint"
  vpc_id      = var.vpc_id

  ingress {
    description = "Allow MongoDB Atlas private endpoint port range for VPC"
    from_port   = 1024
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  tags = var.tags
}
