locals {
  master_creds = jsondecode(data.aws_secretsmanager_secret_version.creds.secret_string)

  services_config = {
    "catalog-api"   = { has_db = true, has_cache = false, has_mq = true }
    "basket-api"    = { has_db = true, has_cache = true, has_mq = true }
    "ordering-api"  = { has_db = true, has_cache = true, has_mq = true }
    "discount-grpc" = { has_db = false, has_cache = false, has_mq = false }
    "keycloak-svc"  = { has_db = true, has_cache = false, has_mq = true }
  }

  db_services = [
    for name, config in local.services_config : name if config.has_db
  ]
}
