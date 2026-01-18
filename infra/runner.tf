resource "aws_launch_template" "gitlab_runner_lt" {
  name_prefix   = "gitlab-runner-lt-"
  image_id      = data.aws_ssm_parameter.al2023_ami.value
  instance_type = "t3.micro"

  user_data = base64encode(templatefile("${path.module}/userdata.sh", {}))
  depends_on = [aws_iam_role_policy.terraform_permissions]
  
  lifecycle {
    create_before_destroy = true
  }

  network_interfaces {
    security_groups = [aws_security_group.runner_sg.id]
  }

  iam_instance_profile {
    name = aws_iam_instance_profile.runner_profile.name
  }

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "GitLab-Runner"
    }
  }
}

resource "aws_iam_role" "runner_role" {
  name = "gitlab-runner-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ssm_policy" {
  role       = aws_iam_role.runner_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "runner_profile" {
  name = "gitlab-runner-ssm-profile"
  role = aws_iam_role.runner_role.name
}

resource "aws_autoscaling_group" "gitlab_runner_asg" {
  name                = "gitlab-runner-asg"
  desired_capacity    = 1
  max_size            = 1
  min_size            = 1
  vpc_zone_identifier = module.vpc.private_subnets

  launch_template {
    id      = aws_launch_template.gitlab_runner_lt.id
    version = "$Latest"
  }

  health_check_type         = "EC2"
  health_check_grace_period = 60
}

resource "aws_security_group" "runner_sg" {
  name        = "gitlab-runner-sg"
  description = "Allow egress for GitLab Runner"
  vpc_id      = module.vpc.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_iam_role_policy" "terraform_permissions" {
  name = "TerraformExecutionPolicy"
  role = aws_iam_role.runner_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "mq:ListBrokers",
          "mq:DescribeBroker",
          "secretsmanager:ListSecrets",
          "kms:ListAliases"
        ],
        Effect   = "Allow"
        Resource = "*"
      },
      {
        Action = [
          "rds:*",
          "ec2:*",
          "s3:*"
        ],
        Effect   = "Allow"
        Resource = "*"
      },
      {
        Action = [
          "secretsmanager:CreateSecret",
          "secretsmanager:PutSecretValue",
          "secretsmanager:UpdateSecret",
          "secretsmanager:TagResource",
          "secretsmanager:DeleteSecret",
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret",
          "secretsmanager:GetResourcePolicy"
        ],
        Effect   = "Allow"
        Resource = [
          data.aws_secretsmanager_secret.gitlab_token.arn,
          module.rds_postgres.db_instance_master_user_secret_arn,
          "arn:aws:secretsmanager:${data.aws_region.current.id}:${data.aws_caller_identity.current.account_id}:secret:rds!db-*",
          "arn:aws:secretsmanager:${data.aws_region.current.id}:${data.aws_caller_identity.current.account_id}:secret:${var.project_name}/${var.environment}/*"
        ]
      },
      {
        Action   = [
          "kms:Decrypt",
          "kms:Encrypt",
          "kms:DescribeKey",
          "kms:GenerateDataKey"
        ],
        Effect   = "Allow",
        Resource = [module.kms_data.key_arn]
      },
      {
        Action   = [
          "kms:CreateGrant"
        ],
        Effect   = "Allow",
        Resource = [module.kms_data.key_arn],
        Condition = {
          Bool = {
            "kms:GrantIsForAWSResource": "true"
          }
        }
      }
    ]
  })
}
