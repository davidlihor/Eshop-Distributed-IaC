module "rds_postgres" {
  source  = "terraform-aws-modules/rds/aws"
  version = "~> 7.0"

  identifier = "${var.project_name}-postgres"

  engine                = "postgres"
  engine_version        = "16.3"
  family                = "postgres16"
  major_engine_version  = "16"
  instance_class        = "db.t4g.micro"
  storage_type          = "gp3"
  allocated_storage     = 20
  max_allocated_storage = 100

  db_name  = "management"
  username = "db_admin"
  port     = 5432

  manage_master_user_password = true

  vpc_security_group_ids = [aws_security_group.rds_sg.id]
  db_subnet_group_name   = module.vpc.database_subnet_group
  publicly_accessible    = false

  kms_key_id        = module.kms_data.key_arn
  storage_encrypted = true

  monitoring_interval    = "30"
  monitoring_role_name   = "${var.project_name}-rds-monitoring-role"
  create_monitoring_role = true

  backup_window           = "03:00-06:00"
  maintenance_window      = "Mon:00:00-Mon:03:00"
  backup_retention_period = 1

  deletion_protection = var.is_production
  skip_final_snapshot = !var.is_production

  tags = {
    Project     = var.project_name
    Environment = var.environment
  }
}

resource "random_password" "db_pass" {
  for_each = toset(local.all_services)
  length   = 24
  special  = false
}

