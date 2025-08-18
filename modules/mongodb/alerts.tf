resource "mongodbatlas_alert_configuration" "atlas_host_cpu_usage" {
  count = var.enable_slack_alerts ? 1 : 0

  project_id = mongodbatlas_project.this.id
  enabled    = true

  event_type = "OUTSIDE_METRIC_THRESHOLD"

  notification {
    api_token     = var.slack_api_token
    channel_name  = var.slack_notification_channel
    type_name     = "SLACK"
    interval_min  = 5
    delay_min     = 0
    sms_enabled   = false
    email_enabled = false
  }

  metric_threshold_config {
    metric_name = "NORMALIZED_SYSTEM_CPU_USER"
    operator    = "GREATER_THAN"
    threshold   = 90.0
    units       = "RAW"
    mode        = "AVERAGE"
  }
}

resource "mongodbatlas_alert_configuration" "atlas_host_system_memory" {
  count = var.enable_slack_alerts ? 1 : 0

  project_id = mongodbatlas_project.this.id
  enabled    = true

  event_type = "OUTSIDE_METRIC_THRESHOLD"

  notification {
    api_token     = var.slack_api_token
    channel_name  = var.slack_notification_channel
    type_name     = "SLACK"
    interval_min  = 5
    delay_min     = 0
    sms_enabled   = false
    email_enabled = false
  }

  metric_threshold_config {
    metric_name = "SYSTEM_MEMORY_PERCENT_USED"
    operator    = "GREATER_THAN"
    threshold   = 70.0
    units       = "RAW"
    mode        = "AVERAGE"
  }
}

resource "mongodbatlas_alert_configuration" "atlas_host_data_disk" {
  count = var.enable_slack_alerts ? 1 : 0

  project_id = mongodbatlas_project.this.id
  enabled    = true

  event_type = "OUTSIDE_METRIC_THRESHOLD"

  notification {
    api_token     = var.slack_api_token
    channel_name  = var.slack_notification_channel
    type_name     = "SLACK"
    interval_min  = 5
    delay_min     = 0
    sms_enabled   = false
    email_enabled = false
  }

  metric_threshold_config {
    metric_name = "DISK_PARTITION_SPACE_USED_DATA"
    operator    = "GREATER_THAN"
    threshold   = 90
    units       = "RAW"
    mode        = "AVERAGE"
  }
}

resource "mongodbatlas_alert_configuration" "atlas_replset_alerts" {
  count = var.enable_slack_alerts ? 1 : 0

  project_id = mongodbatlas_project.this.id
  enabled    = true

  event_type = "NO_PRIMARY"

  notification {
    api_token     = var.slack_api_token
    channel_name  = var.slack_notification_channel
    type_name     = "SLACK"
    interval_min  = 5
    delay_min     = 0
    sms_enabled   = false
    email_enabled = false
  }
}
