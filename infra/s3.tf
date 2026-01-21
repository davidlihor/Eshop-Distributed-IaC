resource "aws_s3_bucket" "monitoring" {
  for_each = toset(local.monitoring_buckets)
  bucket   = "${var.project_name}-${var.environment}-${each.value}-storage-${random_string.suffix.result}"
  force_destroy = var.environment == "dev" ? true : false

  tags = {
    Name        = "${var.project_name}-${each.value}"
    Environment = var.environment
    Component   = "Monitoring"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "monitoring" {
  for_each = aws_s3_bucket.monitoring
  bucket   = each.value.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_ownership_controls" "monitoring" {
  for_each = aws_s3_bucket.monitoring
  bucket   = each.value.id
  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_s3_bucket_public_access_block" "monitoring" {
  for_each = aws_s3_bucket.monitoring
  bucket   = each.value.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_lifecycle_configuration" "monitoring" {
  for_each = aws_s3_bucket.monitoring
  bucket   = each.value.id

  rule {
    id     = "archive_old_logs"
    status = "Enabled"

    transition {
      days          = 30
      storage_class = "STANDARD_IA"
    }
  }
}

resource "random_string" "suffix" {
  length  = 4
  special = false
  upper   = false
}