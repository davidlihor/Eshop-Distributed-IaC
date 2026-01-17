resource "aws_mq_broker" "rabbit" {
  broker_name = "${var.project_name}-rabbitmq"

  engine_type                = "RabbitMQ"
  engine_version             = "4.2"
  deployment_mode            = "SINGLE_INSTANCE"
  host_instance_type         = "mq.m7g.medium"
  auto_minor_version_upgrade = true

  storage_type        = "ebs"
  publicly_accessible = false
  subnet_ids          = [module.vpc.private_subnets[0]]
  security_groups     = [aws_security_group.mq_sg.id]

  depends_on = [aws_cloudwatch_log_group.rabbitmq_log_group]

  user {
    username = "admin"
    password = random_password.mq_admin_password.result
  }

  logs {
    general = true
    audit   = false
  }

  encryption_options {
    use_aws_owned_key = false
    kms_key_id        = module.kms_data.key_arn
  }

  maintenance_window_start_time {
    day_of_week = "SUNDAY"
    time_of_day = "03:00"
    time_zone   = "UTC"
  }

  tags = {
    Environment = var.environment
  }
}

resource "aws_cloudwatch_log_group" "rabbitmq_log_group" {
  name              = "/aws/amazonmq/broker/${var.project_name}-rabbitmq/general"
  retention_in_days = 30
  log_group_class   = "INFREQUENT_ACCESS"
}

resource "random_password" "mq_admin_password" {
  length  = 32
  special = false
}

resource "aws_secretsmanager_secret" "mq_admin_credentials" {
  name = "${var.project_name}/${var.environment}/mq/admin"
  tags = {
    "${var.project_name}:mq:brokerArn" = aws_mq_broker.rabbit.arn
  }
}

resource "aws_secretsmanager_secret_version" "mq_admin_credentials_val" {
  secret_id     = aws_secretsmanager_secret.mq_admin_credentials.id
  secret_string = jsonencode({
    username = "admin"
    password = random_password.mq_admin_password.result
  })
}