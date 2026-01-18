resource "aws_secretsmanager_secret" "service_db_secrets" {
  for_each                = toset(local.db_services)
  name                    = "${var.project_name}/${var.environment}/db/${each.key}"
  kms_key_id              = data.aws_kms_alias.data_key.target_key_arn
  recovery_window_in_days = 0
}

resource "aws_secretsmanager_secret_version" "service_db_secrets_val" {
  for_each  = toset(local.db_services)
  secret_id = aws_secretsmanager_secret.service_db_secrets[each.key].id
  secret_string = jsonencode({
    db_username = postgresql_role.service_user[each.key].name
    db_password = random_password.db_pass[each.key].result
    db_name     = postgresql_database.service_db[each.key].name
    db_host     = data.aws_db_instance.database.address
  })
}

resource "aws_secretsmanager_secret" "mq_service_secrets" {
  for_each                = toset(local.mq_services)
  name                    = "${var.project_name}/${var.environment}/mq/${each.key}"
  kms_key_id              = data.aws_kms_alias.data_key.target_key_arn
  recovery_window_in_days = 0
}

resource "aws_secretsmanager_secret_version" "mq_service_secrets_val" {
  for_each  = toset(local.mq_services)
  secret_id = aws_secretsmanager_secret.mq_service_secrets[each.key].id
  secret_string = jsonencode({
    mq_username = replace(each.key, "-", "_")
    mq_password = random_password.mq_service_pass[each.key].result
    mq_host = replace(replace(data.aws_mq_broker.rabbit.instances[0].endpoints[0], "amqps://", ""), ":5671", "")
  })
}
