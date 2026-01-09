resource "random_password" "db_pass" {
  for_each = toset(local.db_services)
  length   = 24
  special  = false
}

resource "postgresql_role" "service_user" {
  for_each = toset(local.db_services)
  name     = replace(each.key, "-", "_")
  login    = true
  password = random_password.db_pass[each.key].result
}

resource "postgresql_database" "service_db" {
  for_each = toset(local.db_services)
  name     = "${replace(each.key, "-", "_")}_db"
  owner    = postgresql_role.service_user[each.key].name
}

resource "postgresql_grant" "service_db_grant" {
  for_each    = toset(local.db_services)
  database    = postgresql_database.service_db[each.key].name
  role        = postgresql_role.service_user[each.key].name
  object_type = "database"
  privileges  = ["ALL"]
}
