module "kms_eks" {
  source  = "terraform-aws-modules/kms/aws"
  version = "~> 4.1"

  description             = "Encryption key for EKS Secrets and EBS volumes"
  deletion_window_in_days = 7
  enable_key_rotation     = true
  is_enabled              = true

  aliases               = ["${var.project_name}-eks-key"]
  enable_default_policy = true

  key_owners = [data.aws_caller_identity.current.arn]
  key_users  = [data.aws_caller_identity.current.arn]

  tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

module "kms_data" {
  source  = "terraform-aws-modules/kms/aws"
  version = "~> 4.1"

  description             = "Encryption key for Valkey and RDS"
  deletion_window_in_days = 7
  enable_key_rotation     = true
  is_enabled              = true

  aliases               = ["${var.project_name}-data-key"]
  enable_default_policy = true

  key_owners = [data.aws_caller_identity.current.arn]
  key_users  = [data.aws_caller_identity.current.arn]

  tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

