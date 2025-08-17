# Check if main.tf has duplicate terraform blocks
# Edit main.tf and make sure it only has ONE terraform block at the top

# main.tf
terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Configure AWS Provider
provider "aws" {
  region = var.aws_region
}

# Data source to get the latest Ubuntu AMI
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# Data source to get current public IP
data "http" "my_ip" {
  url = "https://ipv4.icanhazip.com"
}

# Create VPC
resource "aws_vpc" "exchange_monitor_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name        = "exchange-monitor-vpc"
    Environment = "production"
    Project     = "exchange-rate-monitor"
  }
}

# Create Internet Gateway
resource "aws_internet_gateway" "exchange_monitor_igw" {
  vpc_id = aws_vpc.exchange_monitor_vpc.id

  tags = {
    Name = "exchange-monitor-igw"
  }
}

# Create public subnet
resource "aws_subnet" "exchange_monitor_subnet" {
  vpc_id                  = aws_vpc.exchange_monitor_vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = true

  tags = {
    Name = "exchange-monitor-subnet"
  }
}

# Get available AZs
data "aws_availability_zones" "available" {
  state = "available"
}

# Create route table
resource "aws_route_table" "exchange_monitor_rt" {
  vpc_id = aws_vpc.exchange_monitor_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.exchange_monitor_igw.id
  }

  tags = {
    Name = "exchange-monitor-route-table"
  }
}

# Associate route table with subnet
resource "aws_route_table_association" "exchange_monitor_rta" {
  subnet_id      = aws_subnet.exchange_monitor_subnet.id
  route_table_id = aws_route_table.exchange_monitor_rt.id
}

# Create security group
resource "aws_security_group" "exchange_monitor_sg" {
  name_prefix = "exchange-monitor-sg"
  vpc_id      = aws_vpc.exchange_monitor_vpc.id

  # SSH access from your IP only
  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["${chomp(data.http.my_ip.response_body)}/32"]
  }

  # All outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "exchange-monitor-security-group"
  }
}

# Create key pair
resource "aws_key_pair" "exchange_monitor_key" {
  key_name   = "exchange-monitor-key"
  public_key = file(var.public_key_path)

  tags = {
    Name = "exchange-monitor-key"
  }
}

# Create EC2 instance
resource "aws_instance" "exchange_monitor" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.instance_type
  key_name               = aws_key_pair.exchange_monitor_key.key_name
  vpc_security_group_ids = [aws_security_group.exchange_monitor_sg.id]
  subnet_id              = aws_subnet.exchange_monitor_subnet.id

  # User data script to install dependencies and setup the application
  user_data = base64encode(templatefile("${path.module}/user_data.sh", {
    sender_email    = var.sender_email
    sender_password = var.sender_password
    target_rate     = var.target_rate
  }))

  root_block_device {
    volume_type = "gp3"
    volume_size = 8
    encrypted   = true
  }

  tags = {
    Name        = "exchange-rate-monitor"
    Environment = "production"
    Project     = "exchange-rate-monitor"
  }
}

# Create CloudWatch billing alarm
resource "aws_cloudwatch_metric_alarm" "billing_alarm" {
  alarm_name          = "exchange-monitor-billing-alarm"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "EstimatedCharges"
  namespace           = "AWS/Billing"
  period              = "86400"
  statistic           = "Maximum"
  threshold           = var.billing_threshold
  alarm_description   = "This metric monitors estimated charges"
  alarm_actions       = [aws_sns_topic.billing_alerts.arn]

  dimensions = {
    Currency = "USD"
  }

  tags = {
    Name = "exchange-monitor-billing-alarm"
  }
}

# SNS topic for billing alerts
resource "aws_sns_topic" "billing_alerts" {
  name = "exchange-monitor-billing-alerts"

  tags = {
    Name = "exchange-monitor-billing-alerts"
  }
}

# SNS topic subscription
resource "aws_sns_topic_subscription" "billing_email" {
  topic_arn = aws_sns_topic.billing_alerts.arn
  protocol  = "email"
  endpoint  = var.alert_email
}

# IAM role for CloudWatch logs (optional)
resource "aws_iam_role" "exchange_monitor_role" {
  name = "exchange-monitor-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name = "exchange-monitor-role"
  }
}

# IAM policy for CloudWatch logs
resource "aws_iam_role_policy" "exchange_monitor_policy" {
  name = "exchange-monitor-policy"
  role = aws_iam_role.exchange_monitor_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:*:*:*"
      }
    ]
  })
}

# IAM instance profile
resource "aws_iam_instance_profile" "exchange_monitor_profile" {
  name = "exchange-monitor-profile"
  role = aws_iam_role.exchange_monitor_role.name
}