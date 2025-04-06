provider "aws" {
  region = var.aws_region
}

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
  
  # If you want to use S3 backend for state storage (recommended for teams)
  # backend "s3" {
  #   bucket = "your-terraform-state-bucket"
  #   key    = "microservices/terraform.tfstate"
  #   region = "eu-north-1"
  # }
}

# Use data sources for existing ECR repositories
data "aws_ecr_repository" "repositories" {
  for_each = toset(var.ecr_repositories)
  name     = each.key
  registry_id = var.aws_account_id
}

# Get current AWS account ID for use in other resources
data "aws_caller_identity" "current" {}