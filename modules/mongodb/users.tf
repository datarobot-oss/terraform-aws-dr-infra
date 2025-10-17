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
