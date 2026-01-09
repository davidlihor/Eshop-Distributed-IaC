variable "region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
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
