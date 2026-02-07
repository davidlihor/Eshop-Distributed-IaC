terraform {
  required_version = ">= 1.13.3"

  required_providers {
    postgresql = {
      source  = "cyrilgdn/postgresql"
      version = "~> 1.26"
    }
    rabbitmq = {
      source  = "cyrilgdn/rabbitmq",
      version = "~> 1.10"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.7"
    }
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.27"
    }
  }

  backend "s3" {
    key          = "config/terraform.tfstate"
    region       = "us-east-1"
    encrypt      = true
    use_lockfile = true
  }
}
