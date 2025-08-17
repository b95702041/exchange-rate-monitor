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
