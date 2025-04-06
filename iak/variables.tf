variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "eu-north-1"
}

variable "aws_account_id" {
  description = "AWS Account ID - retrieved dynamically, do not hardcode"
  type        = string
  # No default - must be provided via terraform.tfvars or environment
}

variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "microservices"
}

variable "environment" {
  description = "Environment (dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "availability_zones" {
  description = "List of availability zones"
  type        = list(string)
  default     = ["eu-north-1a", "eu-north-1b", "eu-north-1c"]
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for private subnets"
  type        = list(string)
  default     = ["10.0.4.0/24", "10.0.5.0/24", "10.0.6.0/24"]
}

variable "database_subnet_cidrs" {
  description = "CIDR blocks for database subnets"
  type        = list(string)
  default     = ["10.0.7.0/24", "10.0.8.0/24", "10.0.9.0/24"]
}

variable "ecr_repositories" {
  description = "List of ECR repository names"
  type        = list(string)
  default     = ["deploy/userservice", "deploy/locationservice", "deploy/reviewservice"]
}

variable "db_username" {
  description = "Database admin username"
  type        = string
  default     = "postgres"
  sensitive   = true
}

variable "db_password" {
  description = "Database admin password"
  type        = string
  default     = "postgres"  # Change this in production or use environment variables
  sensitive   = true
}

variable "db_name" {
  description = "Database name"
  type        = string
  default     = "microservices"
}

variable "service_cpu" {
  description = "CPU units for services"
  type        = number
  default     = 256
}

variable "service_memory" {
  description = "Memory for services in MiB"
  type        = number
  default     = 512
}

variable "postgres_container_port" {
  description = "Port exposed by the postgres container"
  type        = number
  default     = 5432
}

variable "rabbitmq_container_port" {
  description = "Port exposed by the rabbitmq container"
  type        = number
  default     = 5672
}

variable "rabbitmq_management_port" {
  description = "Management port exposed by the rabbitmq container"
  type        = number
  default     = 15672
}

variable "service_container_port" {
  description = "Port exposed by the service containers"
  type        = number
  default     = 8080
}