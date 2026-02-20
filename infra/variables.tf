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

variable "gateway_api_version" {
  description = "Gateway API CRD bundle version"
  type        = string
  default     = "v1.4.0"
}

variable "admin_arn" {
  type        = string
  description = "ARN of the admin user"
  default     = ""
}

variable "billing_mode" {
  description = "DynamoDB billing mode (PROVISIONED or PAY_PER_REQUEST)"
  type        = string
  default     = "PAY_PER_REQUEST"
}

variable "read_capacity" {
  description = "Read capacity units for DynamoDB (only for PROVISIONED mode)"
  type        = number
  default     = 5
}

variable "write_capacity" {
  description = "Write capacity units for DynamoDB (only for PROVISIONED mode)"
  type        = number
  default     = 5
}

variable "domain_name" {
  description = "Main domain name"
  type        = string
  default     = "davidlihor.com"
}
