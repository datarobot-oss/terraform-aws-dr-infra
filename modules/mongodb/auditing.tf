resource "mongodbatlas_auditing" "database_audit" {
  project_id = mongodbatlas_project.this.id
audit_filter = jsonencode({
  "$or" : [
    {
      "users" : {
        "$in" : [
          {
            "user" : var.mongodb_admin_arns,
            "db" : "$external"
          }
        ]
      }
    },
    {
      "$and" : [
        {
          "$or" : [
            {
              "users" : {
                "$elemMatch" : {
                  "$or" : [
                    { "db" : "admin" },
                    { "db" : "$external" }
                  ]
                }
              }
            },
            {
              "roles" : {
                "$elemMatch" : {
                  "$or" : [
                    { "db" : "admin" }
                  ]
                }
              }
            }
          ]
        },
        {
          "$or" : [
            {
              "atype" : "authCheck",
              "param.command" : {
                "$in" : [
                  "aggregate", "count", "distinct", "group", "mapReduce",
                  "geoNear", "geoSearch", "eval", "find", "getLastError",
                  "getMore", "getPrevError", "parallelCollectionScan",
                  "delete", "findAndModify", "insert", "update", "resetError"
                ]
              }
            },
            {
              "atype" : {
                "$in" : [
                  "authenticate", "createCollection", "createDatabase", "createIndex",
                  "renameCollection", "dropCollection", "dropDatabase", "dropIndex",
                  "createUser", "dropUser", "dropAllUsersFromDatabase", "updateUser",
                  "grantRolesToUser", "revokeRolesFromUser", "createRole", "updateRole",
                  "dropRole", "dropAllRolesFromDatabase", "grantRolesToRole",
                  "revokeRolesFromRole", "grantPrivilegesToRole", "revokePrivilegesFromRole",
                  "enableSharding", "shardCollection", "addShard", "removeShard",
                  "shutdown", "applicationMessage", "insert", "update"
                ]
              }
            }
          ]
        }
      ]
    }
  ]
})
  audit_authorization_success = true
  enabled                     = var.db_audit_enable
}
