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
