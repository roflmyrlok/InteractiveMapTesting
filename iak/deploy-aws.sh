#!/bin/bash

# Script to deploy services to AWS
# This script assumes you're already logged in to AWS CLI

# Stop on errors
set -e

# Display usage information
usage() {
  echo "Usage: ./deploy-aws.sh [options]"
  echo "Options:"
  echo "  --region REGION     AWS region (default: eu-north-1)"
  echo "  --services SERVICE  Services to deploy (default: all - userservice, locationservice, reviewservice)"
  echo "  --help              Display this help message"
  exit 1
}

# Parse command line arguments
AWS_REGION="eu-north-1"
DEPLOY_ALL_SERVICES=true
SERVICES_TO_DEPLOY=()

while [[ $# -gt 0 ]]; do
  case "$1" in
    --region)
      AWS_REGION="$2"
      shift 2
      ;;
    --services)
      DEPLOY_ALL_SERVICES=false
      SERVICES_TO_DEPLOY+=("$2")
      shift 2
      ;;
    --help)
      usage
      ;;
    *)
      echo "Unknown option: $1"
      usage
      ;;
  esac
done

# Set up services
if [ "$DEPLOY_ALL_SERVICES" = true ]; then
  SERVICES=("userservice" "locationservice" "reviewservice")
else
  SERVICES=("${SERVICES_TO_DEPLOY[@]}")
fi

# Get AWS Account ID without hardcoding it
echo "Retrieving AWS Account ID..."
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)

if [ -z "$AWS_ACCOUNT_ID" ]; then
  echo "Error: Could not retrieve AWS Account ID. Make sure you're logged in with 'aws configure'"
  exit 1
fi

# Set ECR registry URL
ECR_REGISTRY="${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"
echo "Using ECR registry: ${ECR_REGISTRY}"

# Authenticate with ECR
echo "Logging in to Amazon ECR..."
aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin $ECR_REGISTRY

# Check if repositories exist, create if they don't
for service in "${SERVICES[@]}"; do
  repo_name="deploy/${service}"
  
  echo "Checking if repository ${repo_name} exists..."
  if ! aws ecr describe-repositories --repository-names ${repo_name} --region ${AWS_REGION} 2>/dev/null; then
    echo "Creating ECR repository: ${repo_name}"
    aws ecr create-repository --repository-name ${repo_name} --region ${AWS_REGION}
  fi
done

# Get current directory
CURRENT_DIR=$(pwd)
ROOT_DIR=$(dirname "$CURRENT_DIR")

# Build and push each service
for service in "${SERVICES[@]}"; do
  echo "Building and pushing ${service}..."
  
  # Explicitly map service names to directories
  if [[ "$service" == "userservice" ]]; then
    service_dir="${ROOT_DIR}/backend/UserService"
  elif [[ "$service" == "locationservice" ]]; then
    service_dir="${ROOT_DIR}/backend/LocationService"
  elif [[ "$service" == "reviewservice" ]]; then
    service_dir="${ROOT_DIR}/backend/ReviewService"
  else
    echo "Unknown service: $service"
    continue
  fi
  
  # Check if directory exists
  if [ ! -d "$service_dir" ]; then
    echo "Error: Directory for $service not found at $service_dir"
    echo "Current directory: $(pwd)"
    echo "Root directory: $ROOT_DIR"
    echo "Please check your directory structure."
    exit 1
  fi
  
  # Navigate to service directory
  cd "$service_dir"
  
  # Build the Docker image
  echo "Building Docker image for ${service}..."
  docker build -t deploy/${service}:latest .
  
  # Tag the Docker image
  echo "Tagging Docker image for ${service}..."
  docker tag deploy/${service}:latest ${ECR_REGISTRY}/deploy/${service}:latest
  
  # Push the Docker image
  echo "Pushing Docker image for ${service}..."
  docker push ${ECR_REGISTRY}/deploy/${service}:latest
  
  # Return to original directory
  cd "$CURRENT_DIR"
done

# Create terraform.tfvars if it doesn't exist
echo "Setting up Terraform variables..."

if [ ! -f "terraform.tfvars" ]; then
  echo "Creating terraform.tfvars file..."
  cat > terraform.tfvars << EOF
aws_region = "${AWS_REGION}"
aws_account_id = "${AWS_ACCOUNT_ID}"
EOF
  echo "Created terraform.tfvars with AWS account ID and region"
fi

# Initialize Terraform
echo "Initializing Terraform..."
terraform init

# Create a plan
echo "Creating Terraform plan..."
terraform plan -out=tf.plan

# Ask for confirmation before applying
read -p "Do you want to apply the Terraform changes? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
  echo "Applying Terraform changes..."
  terraform apply tf.plan
  
  # Output the ALB DNS name
  echo "Deployment complete!"
  alb_dns=$(terraform output -raw alb_dns_name 2>/dev/null || echo "ALB DNS name not available")
  
  if [ -n "$alb_dns" ]; then
    echo "Your application is available at: http://${alb_dns}"
  fi
else
  echo "Terraform apply canceled."
fi

echo "Script completed!"
