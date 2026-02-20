module "coupons_table" {
  source  = "terraform-aws-modules/dynamodb-table/aws"
  version = "5.5.0"

  name         = "${var.project_name}-${var.environment}-Coupons"
  billing_mode = var.billing_mode
  hash_key     = "Id"

  read_capacity  = var.billing_mode == "PROVISIONED" ? var.read_capacity : null
  write_capacity = var.billing_mode == "PROVISIONED" ? var.write_capacity : null

  attributes = [
    {
      name = "Id"
      type = "N"
    },
    {
      name = "CouponCode"
      type = "S"
    },
    {
      name = "ProductId"
      type = "S"
    }
  ]

  global_secondary_indexes = [
    {
      name            = "CouponCode-ProductId-index"
      hash_key        = "CouponCode"
      range_key       = "ProductId"
      projection_type = "ALL"

      read_capacity  = var.billing_mode == "PROVISIONED" ? var.read_capacity : null
      write_capacity = var.billing_mode == "PROVISIONED" ? var.write_capacity : null
    }
  ]

  server_side_encryption_kms_key_arn = module.kms_data.key_arn
  server_side_encryption_enabled = true
  point_in_time_recovery_enabled = true
  ttl_enabled = false

  tags = {
    Name        = "${var.project_name}-${var.environment}-Coupons"
    Environment = var.environment
    Project     = var.project_name
  }
}

module "counters_table" {
  source  = "terraform-aws-modules/dynamodb-table/aws"
  version = "5.5.0"

  name         = "${var.project_name}-${var.environment}-Counters"
  billing_mode = var.billing_mode
  hash_key     = "Id"

  read_capacity  = var.billing_mode == "PROVISIONED" ? var.read_capacity : null
  write_capacity = var.billing_mode == "PROVISIONED" ? var.write_capacity : null

  attributes = [
    {
      name = "Id"
      type = "S"
    }
  ]

  server_side_encryption_enabled = true
  server_side_encryption_kms_key_arn = module.kms_data.key_arn
  point_in_time_recovery_enabled = true
  ttl_enabled = false

  tags = {
    Name        = "${var.project_name}-${var.environment}-Counters"
    Environment = var.environment
    Project     = var.project_name
  }
}

resource "aws_iam_policy" "discount_dynamodb_policy" {
  name        = "${var.project_name}-${var.environment}-discount-dynamodb-policy"
  description = "IAM policy for Discount.Grpc service to access DynamoDB tables"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "DynamoDBTableAccess"
        Effect = "Allow"
        Action = [
          "dynamodb:PutItem",
          "dynamodb:GetItem",
          "dynamodb:UpdateItem",
          "dynamodb:DeleteItem",
          "dynamodb:Query",
          "dynamodb:Scan",
          "dynamodb:DescribeTable"
        ]
        Resource = [
          module.coupons_table.dynamodb_table_arn,
          "${module.coupons_table.dynamodb_table_arn}/index/*",
          module.counters_table.dynamodb_table_arn
        ]
      },
      {
        Sid    = "KMSAccess"
        Effect = "Allow"
        Action = [
          "kms:Decrypt",
          "kms:DescribeKey",
          "kms:GenerateDataKey*"
        ]
        Resource = [module.kms_data.key_arn]
      },
      {
        Sid    = "DynamoDBTableCreate"
        Effect = "Allow"
        Action = [
          "dynamodb:CreateTable"
        ]
        Resource = [
          "arn:aws:dynamodb:${var.region}:*:table/${var.project_name}-${var.environment}-*"
        ]
      }
    ]
  })

  tags = {
    Name        = "${var.project_name}-${var.environment}-discount-dynamodb-policy"
    Environment = var.environment
    Project     = var.project_name
  }
}

resource "aws_iam_role" "discount_role" {
  name = "${var.project_name}-${var.environment}-discount-role-pod-id"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "pods.eks.amazonaws.com"
        }
        Action = [
          "sts:AssumeRole",
          "sts:TagSession"
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "discount_attach" {
  role       = aws_iam_role.discount_role.name
  policy_arn = aws_iam_policy.discount_dynamodb_policy.arn
}

resource "aws_eks_pod_identity_association" "discount_assoc" {
  cluster_name    = module.eks.cluster_name
  namespace       = "${var.project_name}-${var.environment}"
  service_account = "discount-sa"
  role_arn        = aws_iam_role.discount_role.arn
}
