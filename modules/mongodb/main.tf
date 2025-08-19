data "aws_region" "this" {}
data "aws_regions" "current" {}

locals {
  region      = upper(replace(data.aws_region.this.name, "-", "_"))
  copy_region = upper(replace(tolist(setsubtract(data.aws_regions.current.names, [data.aws_region.this.name]))[0], "-", "_"))
}

resource "mongodbatlas_project" "this" {
  org_id = var.atlas_org_id
  name   = var.name
}

resource "mongodbatlas_cluster" "this" {
  project_id = mongodbatlas_project.this.id
  name       = var.name

  provider_name = "AWS"
  cluster_type  = "REPLICASET"

  pit_enabled                    = true
  cloud_backup                   = true
  termination_protection_enabled = var.termination_protection_enabled

  mongo_db_major_version = var.mongodb_version
  version_release_system = "LTS"

  auto_scaling_disk_gb_enabled = var.atlas_auto_scaling_disk_gb_enabled
  disk_size_gb                 = var.atlas_disk_size
  provider_instance_size_name  = var.atlas_instance_type

  replication_specs {
    num_shards = 1
    regions_config {
      region_name     = local.region
      electable_nodes = 3
      priority        = 7
      read_only_nodes = 0
    }
  }

  advanced_configuration {
    javascript_enabled           = true
    minimum_enabled_tls_protocol = "TLS1_2"
  }

  lifecycle {
    ignore_changes = [disk_size_gb]
  }
}

resource "mongodbatlas_cloud_backup_schedule" "aws_mongo_atlas_automated_cloud_backup" {
  project_id   = mongodbatlas_project.this.id
  cluster_name = mongodbatlas_cluster.this.name

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
    region_name = local.copy_region

    replication_spec_id = mongodbatlas_cluster.this.replication_specs[*].id[0]
    should_copy_oplogs  = true
  }
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

resource "aws_security_group" "this" {
  name        = "${var.name}-mongodb"
  description = "Allow access to mongodb atlas private endpoint"
  vpc_id      = var.vpc_id

  ingress {
    description = "Allow MongoDB Atlas private endpoint port range for VPC"
    from_port   = 1024
    to_port     = 1124
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  tags = var.tags
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
