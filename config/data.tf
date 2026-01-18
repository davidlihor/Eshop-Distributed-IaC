data "aws_db_instance" "database" {
  db_instance_identifier = "eshop-postgres"
}

data "aws_secretsmanager_secrets" "rds_search" {
  filter {
    name   = "tag-key"
    values = ["aws:rds:primaryDBInstanceArn"]
  }
  filter {
    name   = "tag-value"
    values = [data.aws_db_instance.database.db_instance_arn]
  }
}

data "aws_secretsmanager_secret_version" "creds" {
  secret_id = tolist(data.aws_secretsmanager_secrets.rds_search.arns)[0]
}


data "aws_mq_broker" "rabbit" {
  broker_name = "eshop-rabbitmq"
}

data "aws_secretsmanager_secrets" "mq_search" {
  filter {
    name   = "tag-key"
    values = ["${var.project_name}:mq:brokerArn"]
  }
  filter {
    name   = "tag-value"
    values = [data.aws_mq_broker.rabbit.arn]
  }
}

data "aws_secretsmanager_secret_version" "mq_creds" {
  secret_id = tolist(data.aws_secretsmanager_secrets.mq_search.arns)[0]
}

data "aws_kms_alias" "data_key" {
  name = "alias/${var.project_name}-data-key"
}