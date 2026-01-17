resource "random_password" "mq_service_pass" {
  for_each = toset(local.mq_services)
  length   = 32
  special  = false
}

resource "rabbitmq_user" "service_user" {
  for_each = toset(local.mq_services)
  name     = replace(each.key, "-", "_")
  password = random_password.mq_service_pass[each.key].result
}

resource "rabbitmq_permissions" "service_permissions" {
  for_each = toset(local.mq_services)
  user     = rabbitmq_user.service_user[each.key].name
  vhost    = "/"
  permissions {
    configure = ".*"
    write     = ".*"
    read      = ".*"
  }
}
