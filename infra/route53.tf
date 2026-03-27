resource "aws_route53_zone" "main" {
  name = var.domain_name
}

resource "aws_iam_role" "external_dns_pod_id" {
  name = "${var.project_name}-external-dns-pod-id"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "sts:AssumeRole",
          "sts:TagSession"
        ]
        Effect = "Allow"
        Principal = {
          Service = "pods.eks.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_policy" "external_dns" {
  name        = "AllowExternalDNSUpdates"
  description = "Allow External-DNS to modify Route 53"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["route53:ChangeResourceRecordSets"]
        Resource = ["arn:aws:route53:::hostedzone/${aws_route53_zone.main.zone_id}"]
      },
      {
        Effect   = "Allow"
        Action   = [
          "route53:ListHostedZones",
          "route53:ListResourceRecordSets",
          "route53:ListHostedZonesByName"
        ]
        Resource = ["*"]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "external_dns_attach" {
  role       = aws_iam_role.external_dns_pod_id.name
  policy_arn = aws_iam_policy.external_dns.arn
}

resource "aws_eks_pod_identity_association" "external_dns" {
  cluster_name    = module.eks.cluster_name
  namespace       = "external-dns"
  service_account = "external-dns"
  role_arn        = aws_iam_role.external_dns_pod_id.arn
}


resource "aws_iam_role" "cert_manager_role" {
  name = "${var.project_name}-cert-manager-pod-id"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "sts:AssumeRole",
          "sts:TagSession"
        ]
        Effect = "Allow"
        Principal = {
          Service = "pods.eks.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_policy" "cert_manager_policy" {
  name        = "${var.project_name}-cert-manager-policy"
  description = "Allow Cert Manager to modify Route 53"

  policy      = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = "route53:GetChange"
        Resource = "arn:aws:route53:::change/*"
      },
      {
        Effect   = "Allow"
        Action   = [
          "route53:ChangeResourceRecordSets",
          "route53:ListResourceRecordSets"
        ]
        Resource = "arn:aws:route53:::hostedzone/${aws_route53_zone.main.zone_id}"
      },
      {
        Effect   = "Allow"
        Action   = "route53:ListHostedZonesByName"
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "cert_manager_attach" {
  role       = aws_iam_role.cert_manager_role.name
  policy_arn = aws_iam_policy.cert_manager_policy.arn
}

resource "aws_eks_pod_identity_association" "cert_manager" {
  cluster_name    = module.eks.cluster_name
  namespace       = "cert-manager" 
  service_account = "cert-manager" 
  role_arn        = aws_iam_role.cert_manager_role.arn
}
