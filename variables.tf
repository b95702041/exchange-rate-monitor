# variables.tf
variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t2.micro"
}

variable "public_key_path" {
  description = "Path to the public key file"
  type        = string
  default     = "~/.ssh/id_rsa.pub"
}

variable "sender_email" {
  description = "Gmail address for sending notifications"
  type        = string
  sensitive   = true
}

variable "sender_password" {
  description = "Gmail app password"
  type        = string
  sensitive   = true
}

variable "target_rate" {
  description = "Target exchange rate (USD to TWD)"
  type        = number
  default     = 33.0
}

variable "billing_threshold" {
  description = "Billing alarm threshold in USD"
  type        = number
  default     = 1.0
}

variable "alert_email" {
  description = "Email for billing alerts"
  type        = string
  default     = "b95702041@gmail.com"
}

# outputs.tf
output "instance_public_ip" {
  description = "Public IP address of the EC2 instance"
  value       = aws_instance.exchange_monitor.public_ip
}

output "instance_public_dns" {
  description = "Public DNS name of the EC2 instance"
  value       = aws_instance.exchange_monitor.public_dns
}

output "ssh_connection_command" {
  description = "SSH command to connect to the instance"
  value       = "ssh -i ~/.ssh/id_rsa ubuntu@${aws_instance.exchange_monitor.public_ip}"
}

output "billing_alarm_arn" {
  description = "ARN of the billing alarm"
  value       = aws_cloudwatch_metric_alarm.billing_alarm.arn
}

output "security_group_id" {
  description = "ID of the security group"
  value       = aws_security_group.exchange_monitor_sg.id
}

# terraform.tfvars.example
# Copy this to terraform.tfvars and fill in your values

# AWS Configuration
aws_region = "us-east-1"

# Email Configuration (required)
sender_email    = "your-email@gmail.com"
sender_password = "your-gmail-app-password"
alert_email     = "b95702041@gmail.com"

# SSH Key Configuration
public_key_path = "~/.ssh/id_rsa.pub"

# Application Configuration
target_rate = 33.0

# Billing Alert Configuration
billing_threshold = 1.0

# versions.tf
terraform {
  required_version = ">= 1.0"
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    http = {
      source  = "hashicorp/http"
      version = "~> 3.0"
    }
  }
}