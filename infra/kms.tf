module "kms_eks" {
  source  = "terraform-aws-modules/kms/aws"
  version = "~> 4.1"

  description             = "Encryption key for EKS Secrets and EBS volumes"
  deletion_window_in_days = 7
  enable_key_rotation     = true
  is_enabled              = true

  aliases               = ["${var.project_name}-eks-key"]
  enable_default_policy = true

  key_users  = [data.aws_caller_identity.current.arn]
  key_owners = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
  key_statements = [
    {
      sid = "AllowEC2ServiceToUseKey"
      actions = [
        "kms:Encrypt",
        "kms:Decrypt",
        "kms:ReEncrypt*",
        "kms:GenerateDataKey*",
        "kms:DescribeKey",
        "kms:CreateGrant"
      ]
      resources = ["*"]
      principals = [
        {
          type        = "Service"
          identifiers = ["autoscaling.amazonaws.com"]
        },
        {
          type        = "AWS"
          identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/aws-service-role/autoscaling.amazonaws.com/AWSServiceRoleForAutoScaling"]
        }
      ]
      conditions = [
        {
          test     = "Bool"
          variable = "kms:GrantIsForAWSResource"
          values   = ["true"]
        }
      ]
    }
  ]

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

  key_users  = [data.aws_caller_identity.current.arn]
  key_owners = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
  key_statements = [
    {
      sid = "AllowAmazonMQToUseKey"
      actions = [
        "kms:Encrypt",
        "kms:Decrypt",
        "kms:ReEncrypt*",
        "kms:GenerateDataKey*",
        "kms:DescribeKey",
        "kms:CreateGrant"
      ]
      resources = ["*"]
      principals = [
        {
          type        = "Service"
          identifiers = ["mq.amazonaws.com"]
        }
      ]
    },
    {
      sid = "AllowESOToDecryptSecrets"
      actions = [
        "kms:Decrypt",
        "kms:DescribeKey"
      ]
      resources = ["*"]
      principals = [
        {
          type        = "AWS"
          identifiers = [aws_iam_role.external_secrets_role.arn]
        }
      ]
    }
  ]

  tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

