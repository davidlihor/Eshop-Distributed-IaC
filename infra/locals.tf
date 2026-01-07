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
  raw_endpoint   = aws_mq_broker.rabbit.instances[0].endpoints[0]
  host_with_port = replace(local.raw_endpoint, "amqps://", "")
  mq_host        = split(":", local.host_with_port)[0]
  mq_port        = split(":", local.host_with_port)[1]
}

locals {
  actual_db_host = var.db_host != null ? var.db_host : module.rds_postgres.db_instance_address
}