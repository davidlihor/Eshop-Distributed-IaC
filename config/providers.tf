provider "postgresql" {
  host            = data.aws_db_instance.database.address
  port            = data.aws_db_instance.database.port
  database        = data.aws_db_instance.database.db_name
  username        = local.db_admin.username
  password        = local.db_admin.password
  sslmode         = "require"
  connect_timeout = 15
  superuser       = false
}

provider "rabbitmq" {
  endpoint = data.aws_mq_broker.rabbit.instances[0].console_url
  username = local.mq_admin.username
  password = local.mq_admin.password
}

provider "random" {}