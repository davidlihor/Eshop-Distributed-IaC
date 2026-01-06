variable "region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "instance_name" {
  description = "Name of the EC2 instance"
  type        = string
  default     = "eshop-ec2"
}

variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
  default     = "eshop-eks"
}

variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "eshop"
}

variable "environment" {
  description = "Environment of the project"
  type        = string
  default     = "dev"
}

variable "is_production" {
  type        = bool
  default     = false
  description = "Flag to indicate if the environment is production"
}
