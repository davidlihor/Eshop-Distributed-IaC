resource "aws_secretsmanager_secret" "service_db_secrets" {
  for_each = toset(local.db_services)
  name     = "${var.project_name}/${var.environment}/db/${each.key}"
  recovery_window_in_days = 0
}

resource "aws_secretsmanager_secret_version" "service_db_secrets_val" {
  for_each  = toset(local.db_services)
  secret_id = aws_secretsmanager_secret.service_db_secrets[each.key].id
  secret_string = jsonencode({
    username = postgresql_role.service_user[each.key].name
    password = random_password.db_pass[each.key].result
    db_name  = postgresql_database.service_db[each.key].name
    host     = data.aws_db_instance.database.address
  })
}
