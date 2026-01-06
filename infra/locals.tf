locals {
  all_services = keys(local.services_config)
  services_config = {
    "catalog-api"   = { has_db = true, has_cache = false, has_mq = true }
    "basket-api"    = { has_db = true, has_cache = true, has_mq = true }
    "ordering-api"  = { has_db = true, has_cache = true, has_mq = true }
    "discount-grpc" = { has_db = false, has_cache = false, has_mq = false }
    "keycloak-svc"  = { has_db = true, has_cache = false, has_mq = true }
  }
}

locals {
  mq_broker_name = "${var.project_name}-broker"
}
