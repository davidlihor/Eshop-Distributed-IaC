resource "aws_elasticache_serverless_cache" "valkey" {
  name                 = "${var.project_name}-valkey-serverless"
  engine               = "valkey"
  major_engine_version = "8"

  user_group_id = aws_elasticache_user_group.app_users.user_group_id

  cache_usage_limits {
    data_storage {
      maximum = 10
      unit    = "GB"
    }
    ecpu_per_second {
      maximum = 5000
    }
  }

  lifecycle {
    prevent_destroy = false
  }

  description        = "Valkey Serverless for Microservices - Secured via Istio"
  kms_key_id         = module.kms_data.key_arn
  security_group_ids = [aws_security_group.valkey_sg.id]
  subnet_ids         = module.vpc.database_subnets

  daily_snapshot_time      = "03:00"
  snapshot_retention_limit = 7
}

resource "aws_elasticache_user" "service_user" {
  for_each  = toset(local.all_services)
  user_id   = "${var.project_name}-${each.key}"
  user_name = each.key
  engine    = "valkey"

  access_string = "on ~${each.key}:* +@all -@dangerous"
  passwords     = [random_password.redis_pass[each.key].result]
}

resource "random_password" "redis_pass" {
  for_each = toset(local.all_services)
  length   = 24
  special  = false
}

resource "aws_elasticache_user" "default_user" {
  user_id       = "${var.project_name}-default"
  user_name     = "default"
  engine        = "valkey"
  access_string = "off -@all"
  passwords     = [random_password.default_pass.result]
}

resource "random_password" "default_pass" {
  length  = 32
  special = false
}

resource "aws_elasticache_user_group" "app_users" {
  engine        = "valkey"
  user_group_id = "${var.project_name}-users"

  user_ids = concat(
    [aws_elasticache_user.default_user.user_id],
    [for u in aws_elasticache_user.service_user : u.user_id]
  )
}

