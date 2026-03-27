output "route53_nameservers" {
  value       = aws_route53_zone.main.name_servers
  description = "Nameservers to put in registrar"
}

output "rds_endpoint" {
  value       = module.rds_postgres.db_instance_endpoint
  description = "The connection endpoint for the RDS instance"
}

output "cache_endpoint" {
  value       = "${aws_elasticache_serverless_cache.valkey.endpoint[0].address}:${aws_elasticache_serverless_cache.valkey.endpoint[0].port}"
  description = "The connection endpoint for the Valkey serverless cache"
}

output "mq_endpoint" {
  value       = aws_mq_broker.rabbit.instances[0].endpoints[0]
  description = "The connection endpoint for the RabbitMQ broker"
}

output "lgtm_stack_s3_buckets" {
  value = {
    loki    = aws_s3_bucket.monitoring["loki"].id
    mimir   = aws_s3_bucket.monitoring["mimir"].id
    tempo   = aws_s3_bucket.monitoring["tempo"].id
  }
  description = "S3 bucket names for LGTM stack components (Loki, Tempo, Mimir)"
}
