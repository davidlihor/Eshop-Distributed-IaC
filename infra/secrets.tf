resource "aws_secretsmanager_secret" "app_secrets" {
  for_each   = toset(local.all_services)
  name       = "eshop/${var.environment}/${each.key}"
  kms_key_id = module.kms_data.key_arn

  tags = {
    Service     = each.key
    Environment = var.environment
  }
}

resource "aws_secretsmanager_secret_version" "app_secrets_vals" {
  for_each  = local.services_config
  secret_id = aws_secretsmanager_secret.app_secrets[each.key].id

  secret_string = jsonencode(merge(
    each.value.has_db ? {
      DB_CONNECTION = "Server=${module.rds_postgres.db_instance_address};Port=5432;Database=${each.key}_db;Username=${each.key};Password=${random_password.db_pass[each.key].result};"
      DB_PASSWORD   = random_password.db_pass[each.key].result
    } : {},

    each.value.has_cache ? {
      REDIS_CONNECTION = "${aws_elasticache_serverless_cache.valkey.endpoint[0].address}:6379,password=${random_password.redis_pass[each.key].result},ssl=true"
    } : {},

    each.value.has_mq ? {
      RABBIT_USER     = "admin"
      RABBIT_PASSWORD = random_password.mq_admin_pass.result
      RABBIT_HOST     = aws_mq_broker.rabbit.instances[0].endpoints[0]
    } : {}
  ))
}
