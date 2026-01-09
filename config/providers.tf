provider "postgresql" {
  host     = data.aws_db_instance.database.address
  port     = data.aws_db_instance.database.port
  database = data.aws_db_instance.database.db_name 
  username = local.master_creds.username
  password = local.master_creds.password
  sslmode  = "require"
  connect_timeout = 15
  superuser       = false 
}

provider "random" {}