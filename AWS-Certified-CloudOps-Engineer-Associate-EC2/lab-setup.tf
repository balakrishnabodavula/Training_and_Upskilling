ection 01: Introduction & Requirements - Lab Setup
🎯 Lab Objectives
Set up AWS CLI and Terraform
Create basic lab environment
Understand standard tagging strategy
Prepare for CloudOps journey
📋 Prerequisites
AWS Account with appropriate permissions
Terminal/Command Line access
Text editor (VS Code recommended)
🚀 Lab Steps
Step 1: Verify Prerequisites
# Check AWS CLI installation
aws --version

# Check Terraform installation
terraform --version

# Verify AWS credentials
aws sts get-caller-identity
Step 2: Navigate to Lab Directory
cd 01-Introduction-Requirements/labs
Step 3: Initialize Terraform
# Initialize Terraform
terraform init

# Validate configuration
terraform validate

# Review the plan
terraform plan
Step 4: Deploy Lab Infrastructure
# Apply the configuration
terraform apply

# Type 'yes' when prompted
Step 5: Verify Deployment
# Check outputs
terraform output

# Verify VPC creation
aws ec2 describe-vpcs --filters "Name=tag:Name,Values=CloudOps-Lab-VPC"
📁 Lab Files
provider.tf - Terraform provider configuration
variables.tf - Variables and standard tags
lab-setup.tf - Basic VPC infrastructure
outputs.tf - Output values
setup.sh - Automated setup script
🏷️ Standard Tags Applied
All resources are tagged with:

Owner: Imran Shaikh
Project: Internal POC
DM: Kalpesh Kumal
Environment: dev (configurable)
ManagedBy: Terraform
Section: 01-Introduction-Requirements
🧹 Cleanup
Important: Always clean up resources to avoid charges!

# Destroy all resources
terraform destroy

# Type 'yes' when prompted
📊 What Gets Created
1 VPC (10.0.0.0/16)
1 Public Subnet (10.0.1.0/24)
1 Internet Gateway
1 Route Table
Route Table Association
💡 Next Steps
After completing this lab:

Move to Section 02: EC2 for CloudOps
Use the VPC created here for subsequent labs
Remember to clean up when done
🆘 Troubleshooting
Issue: AWS credentials not configured

aws configure
Issue: Terraform not found

# Install Terraform first (see main documentation)
Issue: Permission denied

# Check IAM permissions for EC2, VPC services
