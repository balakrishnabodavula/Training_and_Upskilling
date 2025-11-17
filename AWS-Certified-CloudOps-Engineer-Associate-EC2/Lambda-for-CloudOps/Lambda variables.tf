variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

variable "project_name" {
  description = "Project name"
  type        = string
  default     = "cloudops"
}

# Standard Tags
locals {
  common_tags = {
    Owner       = "Imran Shaikh"
    Project     = "Internal POC"
    DM          = "Kalpesh Kumal"
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

variable "my_ip" {
  description = "Your public IP address for security group access"
  type        = string
  default     = "106.215.179.74/32"
}

variable "key_name" {
  description = "EC2 Key Pair name"
  type        = string
  default     = "demouserNvirginia"
}
