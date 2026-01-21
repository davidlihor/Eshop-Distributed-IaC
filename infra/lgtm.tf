resource "aws_iam_role" "monitoring_s3_role" {
  name = "${var.project_name}-monitoring-s3"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = ["sts:AssumeRole", "sts:TagSession"]
      Effect = "Allow"
      Principal = { Service = "pods.eks.amazonaws.com" }
    }]
  })
}

resource "aws_iam_policy" "monitoring_s3_policy" {
  name        = "${var.project_name}-monitoring-s3-access"
  description = "Allow Loki, Mimir and Tempo to write in their specific buckets"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["s3:ListBucket", "s3:GetBucketLocation"]
        Resource = [for b in aws_s3_bucket.monitoring : b.arn]
      },
      {
        Effect   = "Allow"
        Action   = ["s3:PutObject", "s3:GetObject", "s3:DeleteObject"]
        Resource = [for b in aws_s3_bucket.monitoring : "${b.arn}/*"]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "s3_access_limited" {
  role       = aws_iam_role.monitoring_s3_role.name
  policy_arn = aws_iam_policy.monitoring_s3_policy.arn
}

resource "aws_eks_pod_identity_association" "loki" {
  cluster_name    = module.eks.cluster_name
  namespace       = "monitoring"
  service_account = "loki"
  role_arn        = aws_iam_role.monitoring_s3_role.arn
}

resource "aws_eks_pod_identity_association" "mimir" {
  cluster_name    = module.eks.cluster_name
  namespace       = "monitoring"
  service_account = "mimir"
  role_arn        = aws_iam_role.monitoring_s3_role.arn
}

resource "aws_eks_pod_identity_association" "tempo" {
  cluster_name    = module.eks.cluster_name
  namespace       = "monitoring"
  service_account = "tempo"
  role_arn        = aws_iam_role.monitoring_s3_role.arn
}
