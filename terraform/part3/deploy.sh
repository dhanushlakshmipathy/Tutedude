#!/bin/bash
set -e

# Initialize Terraform
terraform init

# Create ECR Repositories
echo "Creating ECR Repositories..."
terraform apply -target=aws_ecr_repository.backend -target=aws_ecr_repository.frontend -auto-approve

# Get ECR URLs
BACKEND_REPO=$(terraform output -raw ecr_backend_url)
FRONTEND_REPO=$(terraform output -raw ecr_frontend_url)
REGION=$(aws configure get region)
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)

echo "Backend Repo: $BACKEND_REPO"
echo "Frontend Repo: $FRONTEND_REPO"

# Login to ECR
echo "Logging in to ECR..."
aws ecr get-login-password --region $REGION | docker login --username AWS --password-stdin $ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com

# Build and Push Backend
echo "Building and Pushing Backend..."
cd ../../backend
docker build -t flask-backend .
docker tag flask-backend:latest $BACKEND_REPO:latest
docker push $BACKEND_REPO:latest

# Build and Push Frontend
echo "Building and Pushing Frontend..."
cd ../frontend
docker build -t express-frontend .
docker tag express-frontend:latest $FRONTEND_REPO:latest
docker push $FRONTEND_REPO:latest

# Deploy ECS Infrastructure
echo "Deploying ECS Infrastructure..."
cd ../terraform/part3
terraform apply -auto-approve

echo "Part 3 Deployment Complete!"
terraform output alb_dns_name
