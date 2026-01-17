locals {
  services_config = {
    "catalog-api"   = { has_db = true, has_cache = false, has_mq = true }
    "basket-api"    = { has_db = true, has_cache = true, has_mq = true }
    "ordering-api"  = { has_db = true, has_cache = true, has_mq = true }
    "discount-grpc" = { has_db = false, has_cache = false, has_mq = false }
    "keycloak-svc"  = { has_db = true, has_cache = false, has_mq = true }
  }
  
  cache_services = [
    for name, config in local.services_config : name if config.has_cache
  ]
}
