#!/bin/bash

# CloudOps Lab Setup Script
echo "🚀 Starting CloudOps Lab Environment Setup..."

# Check prerequisites
echo "📋 Checking prerequisites..."

# Check AWS CLI
if ! command -v aws &> /dev/null; then
    echo "❌ AWS CLI not found. Please install it first."
    exit 1
fi

# Check Terraform
if ! command -v terraform &> /dev/null; then
    echo "❌ Terraform not found. Please install it first."
    exit 1
fi

# Check AWS credentials
if ! aws sts get-caller-identity &> /dev/null; then
    echo "❌ AWS credentials not configured. Run 'aws configure' first."
    exit 1
fi

echo "✅ Prerequisites check passed!"

# Initialize Terraform
echo "🔧 Initializing Terraform..."
terraform init

# Validate configuration
echo "🔍 Validating Terraform configuration..."
terraform validate

if [ $? -eq 0 ]; then
    echo "✅ Terraform configuration is valid!"
else
    echo "❌ Terraform configuration has errors!"
    exit 1
fi

# Show plan
echo "📋 Showing Terraform plan..."
terraform plan

echo ""
echo "🎯 Setup complete! Next steps:"
echo "1. Review the plan above"
echo "2. Run 'terraform apply' to create resources"
echo "3. Run 'terraform destroy' when done to clean up"
echo ""
echo "💡 Tip: Always clean up resources to avoid charges!"