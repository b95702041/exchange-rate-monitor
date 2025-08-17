# 💱 Exchange Rate Monitor

**Automated USD to TWD Exchange Rate Monitor with Email Alerts**

Monitor USD to TWD exchange rates 24/7 and get instant email notifications when your target rate is reached. Deployed on AWS EC2 Free Tier using Terraform for zero-cost operation.

[![AWS](https://img.shields.io/badge/AWS-EC2-orange.svg)](https://aws.amazon.com/ec2/)
[![Terraform](https://img.shields.io/badge/Terraform-1.0+-blue.svg)](https://www.terraform.io/)
[![Python](https://img.shields.io/badge/Python-3.8+-green.svg)](https://www.python.org/)
[![License](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

## 🎯 Features

- **🔄 Automated Monitoring**: Checks USD/TWD rates 3 times daily
- **📧 Email Notifications**: Instant alerts when target rate is reached
- **☁️ Cloud Deployed**: Runs 24/7 on AWS EC2 Free Tier
- **🏗️ Infrastructure as Code**: Complete Terraform automation
- **🔒 Secure**: VPC, security groups, encrypted storage
- **💰 Free**: $0/month on AWS Free Tier
- **📊 Monitoring**: CloudWatch logs and billing alerts
- **🔧 Production Ready**: Auto-restart, error handling, logging

## 🚀 Quick Start

### Prerequisites

- AWS Account (Free Tier eligible)
- Terraform installed
- Gmail account with App Password
- SSH key pair

### 1. Clone & Setup

```bash
git clone <this-repo>
cd exchange-rate-monitor
```

### 2. Configure Gmail

1. Enable 2-Factor Authentication on Gmail
2. Generate App Password: [Google Account Security](https://myaccount.google.com/security)
3. Save the 16-character app password

### 3. Configure Variables

```bash
cp terraform.tfvars.example terraform.tfvars
nano terraform.tfvars
```

**Required configuration:**
```hcl
sender_email    = "your-email@gmail.com"
sender_password = "your-16-char-app-password"
alert_email     = "b95702041@gmail.com"
target_rate     = 33.0
```

### 4. Deploy

```bash
# Initialize Terraform
terraform init

# Review deployment plan
terraform plan

# Deploy infrastructure
terraform apply
```

### 5. Verify

```bash
# Get instance details
terraform output

# Connect to instance
ssh -i ~/.ssh/id_rsa ubuntu@$(terraform output -raw instance_public_ip)

# Check service status
sudo systemctl status exchange-monitor

# View live logs
tail -f /var/log/exchange-monitor.log
```

## 📁 Project Structure

```
exchange-rate-monitor/
├── README.md                   # This file
├── main.tf                     # Main infrastructure configuration
├── variables.tf                # Variable definitions
├── outputs.tf                  # Output definitions
├── versions.tf                 # Provider versions
├── user_data.sh               # Instance setup script
├── terraform.tfvars.example   # Example configuration
├── terraform.tfvars           # Your configuration (gitignored)
└── .gitignore                 # Git ignore rules
```

## ⚙️ Configuration

### Environment Variables

| Variable | Description | Default | Required |
|----------|-------------|---------|----------|
| `sender_email` | Your Gmail address | - | ✅ |
| `sender_password` | Gmail App Password | - | ✅ |
| `alert_email` | Notification recipient | b95702041@gmail.com | ✅ |
| `target_rate` | Target USD/TWD rate | 33.0 | ❌ |
| `aws_region` | AWS region | us-east-1 | ❌ |
| `billing_threshold` | Billing alert ($) | 1.0 | ❌ |

### Monitoring Schedule

- **Daily at 9:00 AM UTC** - Primary check
- **Daily at 3:00 PM UTC** - Midday check  
- **Daily at 9:00 PM UTC** - Evening check

## 📊 Monitoring & Logs

### Service Status
```bash
# Check if service is running
sudo systemctl status exchange-monitor

# View recent logs
sudo journalctl -u exchange-monitor -f

# Check log file
tail -f /var/log/exchange-monitor.log
```

### Log Format
```
2025-08-17 09:00:01 - INFO - Current rate: 1 USD = 31.2500 TWD
2025-08-17 09:00:01 - INFO - 📊 Target not reached. Current: 31.25, Target: 33.0
2025-08-17 15:00:01 - INFO - 🎯 TARGET REACHED! Current rate: 32.98
2025-08-17 15:00:02 - INFO - ✅ Email notification sent to b95702041@gmail.com
```

### AWS CloudWatch
- **Log Group**: `exchange-monitor`
- **Billing Alerts**: Configured for $1+ usage
- **Metrics**: Instance health monitoring

## 🛠️ Management

### Update Configuration
```bash
# Modify terraform.tfvars
nano terraform.tfvars

# Apply changes
terraform apply
```

### Restart Service
```bash
# SSH to instance
ssh -i ~/.ssh/id_rsa ubuntu@$(terraform output -raw instance_public_ip)

# Restart service
sudo systemctl restart exchange-monitor
```

### Destroy Infrastructure
```bash
# WARNING: This will delete everything
terraform destroy
```

## 🔧 Troubleshooting

### Common Issues

**Service not running:**
```bash
sudo systemctl status exchange-monitor
sudo journalctl -u exchange-monitor --since "1 hour ago"
```

**Email not sending:**
- Verify Gmail App Password is correct
- Check 2-Factor Authentication is enabled
- Test credentials manually

**SSH connection failed:**
- Check your IP hasn't changed
- Verify security group allows your IP
- Ensure SSH key is correct

**Rate limit exceeded:**
```bash
# Check API response
curl "https://api.exchangerate-api.com/v4/latest/USD"
```

### Debug Commands

```bash
# Test email functionality
python3 -c "
from exchange_rate_monitor import ExchangeRateMonitor
monitor = ExchangeRateMonitor()
monitor.check_rate()
"

# Check Python dependencies
python3 -c "import requests, schedule; print('Dependencies OK')"

# View system resources
htop
df -h
free -h
```

## 💰 Cost Breakdown

### AWS Free Tier (12 months)
- **EC2 t2.micro**: 750 hours/month (24/7) - **FREE**
- **EBS Storage**: 30 GB - **FREE** (only using 8 GB)
- **Data Transfer**: 15 GB out - **FREE**
- **CloudWatch**: 10 metrics, 5 GB logs - **FREE**

**Total Monthly Cost: $0**

### After Free Tier (Month 13+)
- **EC2 t2.micro**: ~$8.50/month
- **EBS 8GB**: ~$0.80/month
- **Data Transfer**: ~$0 (minimal usage)

**Total: ~$9.30/month**

## 🔒 Security

### Implemented Security Measures
- ✅ **VPC with private networking**
- ✅ **Security group restricting SSH to your IP**
- ✅ **Encrypted EBS volumes**
- ✅ **IAM roles with minimal permissions**
- ✅ **No hardcoded credentials in code**
- ✅ **Automated security updates**

### Security Best Practices
- Rotate Gmail App Password regularly
- Monitor AWS billing alerts
- Keep Terraform state file secure
- Regularly update instance packages

## 🤝 Contributing

1. Fork the repository
2. Create feature branch (`git checkout -b feature/enhancement`)
3. Commit changes (`git commit -am 'Add enhancement'`)
4. Push to branch (`git push origin feature/enhancement`)
5. Create Pull Request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🆘 Support

- **Issues**: [GitHub Issues](https://github.com/yourusername/exchange-rate-monitor/issues)
- **Documentation**: This README
- **AWS Support**: [AWS Free Tier FAQ](https://aws.amazon.com/free/faqs/)
- **Terraform**: [Terraform Documentation](https://www.terraform.io/docs/)

## 🙏 Acknowledgments

- [ExchangeRate-API](https://exchangerate-api.com/) for free exchange rate data
- [AWS Free Tier](https://aws.amazon.com/free/) for hosting
- [Terraform](https://www.terraform.io/) for infrastructure automation

---

## 📈 Example Notification Email

```
Subject: 🚨 USD/TWD Exchange Rate Alert - Target Reached!

Exchange Rate Alert! 🎯

The USD to TWD exchange rate has reached your target:
Current Rate: 1 USD = 32.9800 TWD
Target Rate: 1 USD = 33.0 TWD

Time: 2025-08-17 15:00:02 UTC

📊 Rate Details:
- Previous rate: 31.2500 TWD
- Target achieved: ✅
- Monitoring continues: The system will keep monitoring for future changes

---
Automated message from Exchange Rate Monitor
Deployed on AWS EC2 via Terraform
```

## 🎉 What's Next?

- [ ] Add support for multiple currency pairs
- [ ] Implement Slack notifications
- [ ] Add historical rate tracking
- [ ] Create web dashboard
- [ ] Add mobile app notifications
- [ ] Implement rate prediction using ML

---

**Happy monitoring! 📊💱**