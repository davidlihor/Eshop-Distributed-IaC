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
      ConnectionStrings__Database = "Host=${module.rds_postgres.db_instance_address};Port=${module.rds_postgres.db_instance_port};Database=management;Username=${module.rds_postgres.db_instance_username};Password=${random_password.rds_master_pass.result};"
    } : {},

    each.value.has_cache ? {
      ConnectionStrings__Redis = "${aws_elasticache_serverless_cache.valkey.endpoint[0].address}:6379,password=${random_password.redis_pass[each.key].result},ssl=true"
    } : {},

    { 
      "Authentication__ClientId" = "reactApp",
      "Authentication__Audience" = "reactApp",
    },

    each.value.has_mq ? {
      MessageBroker__Host     = aws_mq_broker.rabbit.instances[0].endpoints[0]
      MessageBroker__UserName = "admin"
      MessageBroker__Password = random_password.mq_admin_pass.result
    } : {},

    each.key == "keycloak-svc" ? {
      KC_DB_URL      = "jdbc:postgresql://${module.rds_postgres.db_instance_address}:${module.rds_postgres.db_instance_port}/management"
      KC_DB_USERNAME = module.rds_postgres.db_instance_username
      KC_DB_PASSWORD = random_password.rds_master_pass.result

      KK_TO_RMQ_URL      = local.mq_host
      KK_TO_RMQ_PORT     = local.mq_port
      KK_TO_RMQ_USERNAME = "admin"
      KK_TO_RMQ_PASSWORD = random_password.mq_admin_pass.result

      KC_BOOTSTRAP_ADMIN_USERNAME = "admin"
      KC_BOOTSTRAP_ADMIN_PASSWORD = random_password.keycloak_admin_pass.result
    } : {}
  ))
}

resource "random_password" "keycloak_admin_pass" {
  length  = 24
  special = false
}
