resource "random_password" "admin" {
  length      = 32
  special     = false
  min_lower   = 1
  min_upper   = 1
  min_numeric = 1
}

resource "mongodbatlas_database_user" "admin" {
  project_id         = mongodbatlas_project.this.id
  username           = var.mongodb_admin_username
  password           = random_password.admin.result
  auth_database_name = "admin"
  roles {
    role_name     = "readWrite"
    database_name = "admin"
  }
  roles {
    role_name     = "atlasAdmin"
    database_name = "admin"
  }
}

resource "aws_secretsmanager_secret" "admin_password" {
  name                    = "${var.name}-mongodb-admin-password"
  recovery_window_in_days = 0
  tags                    = var.tags
}

resource "aws_secretsmanager_secret_version" "admin_password" {
  secret_id     = aws_secretsmanager_secret.admin_password.id
  secret_string = random_password.admin.result
}

resource "mongodbatlas_database_user" "aws_admins" {
  for_each = var.mongodb_admin_arns

  project_id         = mongodbatlas_project.this.id
  username           = each.value
  auth_database_name = "$external"
  aws_iam_type       = "ROLE"

  roles {
    role_name     = "atlasAdmin"
    database_name = "admin"
  }
}
