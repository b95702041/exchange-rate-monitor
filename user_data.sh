#!/bin/bash
# user_data.sh - Script to automatically setup the exchange rate monitor

set -e

# Update system
apt-get update -y
apt-get upgrade -y

# Install required packages
apt-get install -y python3 python3-pip awscli

# Install Python packages
pip3 install requests schedule

# Create application directory
mkdir -p /opt/exchange-monitor
cd /opt/exchange-monitor

# Create the exchange rate monitor script
cat > exchange_rate_monitor.py << 'EOF'
import requests
import smtplib
import schedule
import time
import logging
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart
from datetime import datetime
import json
import os

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler('/var/log/exchange-monitor.log'),
        logging.StreamHandler()
    ]
)

class ExchangeRateMonitor:
    def __init__(self):
        # Get configuration from environment variables
        self.target_rate = float(os.getenv('TARGET_RATE', '${target_rate}'))
        self.email_recipient = "b95702041@gmail.com"
        self.last_rate = None
        self.notification_sent = False
        
        # Email configuration
        self.smtp_server = "smtp.gmail.com"
        self.smtp_port = 587
        self.sender_email = "${sender_email}"
        self.sender_password = "${sender_password}"
        
        logging.info(f"Exchange Rate Monitor initialized")
        logging.info(f"Target rate: 1 USD = {self.target_rate} TWD")
        logging.info(f"Email notifications will be sent to: {self.email_recipient}")
        
    def get_exchange_rate(self):
        """Fetch current USD to TWD exchange rate"""
        try:
            # Primary API
            url = "https://api.exchangerate-api.com/v4/latest/USD"
            response = requests.get(url, timeout=10)
            data = response.json()
            
            if 'rates' in data and 'TWD' in data['rates']:
                rate = data['rates']['TWD']
                logging.info(f"Current rate: 1 USD = {rate:.4f} TWD")
                return rate
            else:
                logging.error("TWD rate not found in primary API response")
                return self.get_backup_rate()
                
        except Exception as e:
            logging.error(f"Error fetching from primary API: {e}")
            return self.get_backup_rate()
    
    def get_backup_rate(self):
        """Backup exchange rate API"""
        try:
            # Backup API - Fixer.io free tier
            url = "https://api.fixer.io/latest?base=USD&symbols=TWD"
            response = requests.get(url, timeout=10)
            data = response.json()
            
            if 'rates' in data and 'TWD' in data['rates']:
                rate = data['rates']['TWD']
                logging.info(f"Backup API - Current rate: 1 USD = {rate:.4f} TWD")
                return rate
            else:
                logging.error("TWD rate not found in backup API")
                return None
                
        except Exception as e:
            logging.error(f"Error fetching from backup API: {e}")
            return None
    
    def send_email_notification(self, current_rate):
        """Send email notification when target rate is reached"""
        try:
            message = MIMEMultipart()
            message["From"] = self.sender_email
            message["To"] = self.email_recipient
            message["Subject"] = f"🚨 USD/TWD Exchange Rate Alert - Target Reached!"
            
            body = f"""
Exchange Rate Alert! 🎯

The USD to TWD exchange rate has reached your target:
Current Rate: 1 USD = {current_rate:.4f} TWD
Target Rate: 1 USD = {self.target_rate} TWD

Time: {datetime.now().strftime('%Y-%m-%d %H:%M:%S UTC')}

This notification was sent from your AWS EC2 exchange rate monitor.

📊 Rate Details:
- Previous rate: {self.last_rate:.4f} TWD (if available)
- Target achieved: ✅
- Monitoring continues: The system will keep monitoring for future changes

---
Automated message from Exchange Rate Monitor
Deployed on AWS EC2 via Terraform
            """
            
            message.attach(MIMEText(body, "plain"))
            
            server = smtplib.SMTP(self.smtp_server, self.smtp_port)
            server.starttls()
            server.login(self.sender_email, self.sender_password)
            text = message.as_string()
            server.sendmail(self.sender_email, self.email_recipient, text)
            server.quit()
            
            logging.info(f"✅ Email notification sent to {self.email_recipient}")
            self.notification_sent = True
            
        except Exception as e:
            logging.error(f"❌ Error sending email: {e}")
    
    def check_rate(self):
        """Check current rate and send notification if target is reached"""
        try:
            current_rate = self.get_exchange_rate()
            
            if current_rate is None:
                logging.warning("⚠️ Could not fetch exchange rate")
                return
            
            self.last_rate = current_rate
            
            # Check if target rate is reached
            if current_rate <= self.target_rate and not self.notification_sent:
                logging.info(f"🎯 TARGET REACHED! Current rate: {current_rate:.4f}")
                self.send_email_notification(current_rate)
            elif current_rate <= self.target_rate and self.notification_sent:
                logging.info(f"📈 Rate still at target: {current_rate:.4f} (notification already sent)")
            else:
                logging.info(f"📊 Target not reached. Current: {current_rate:.4f}, Target: {self.target_rate}")
                # Reset notification flag if rate goes above target
                if current_rate > self.target_rate:
                    self.notification_sent = False
        
        except Exception as e:
            logging.error(f"❌ Error in check_rate: {e}")
    
    def start_monitoring(self):
        """Start the monitoring service"""
        logging.info("🚀 Starting USD/TWD exchange rate monitoring service...")
        
        # Schedule checks
        schedule.every().day.at("09:00").do(self.check_rate)
        schedule.every().day.at("15:00").do(self.check_rate)  # Additional check
        schedule.every().day.at("21:00").do(self.check_rate)  # Evening check
        
        # Initial check
        self.check_rate()
        
        # Keep the service running
        while True:
            try:
                schedule.run_pending()
                time.sleep(60)  # Check every minute
            except KeyboardInterrupt:
                logging.info("👋 Service stopped by user")
                break
            except Exception as e:
                logging.error(f"❌ Unexpected error: {e}")
                time.sleep(300)  # Wait 5 minutes before retrying

if __name__ == "__main__":
    try:
        monitor = ExchangeRateMonitor()
        monitor.start_monitoring()
    except Exception as e:
        logging.error(f"❌ Failed to start monitor: {e}")
EOF

# Set environment variables
echo "TARGET_RATE=${target_rate}" >> /etc/environment

# Create systemd service
cat > /etc/systemd/system/exchange-monitor.service << 'EOF'
[Unit]
Description=Exchange Rate Monitor Service
After=network.target
Wants=network-online.target

[Service]
Type=simple
User=ubuntu
WorkingDirectory=/opt/exchange-monitor
ExecStart=/usr/bin/python3 /opt/exchange-monitor/exchange_rate_monitor.py
Restart=always
RestartSec=30
StandardOutput=append:/var/log/exchange-monitor.log
StandardError=append:/var/log/exchange-monitor-error.log

# Environment
Environment=TARGET_RATE=${target_rate}

[Install]
WantedBy=multi-user.target
EOF

# Set proper permissions
chown -R ubuntu:ubuntu /opt/exchange-monitor
chmod +x /opt/exchange-monitor/exchange_rate_monitor.py

# Create log file
touch /var/log/exchange-monitor.log
touch /var/log/exchange-monitor-error.log
chown ubuntu:ubuntu /var/log/exchange-monitor*.log

# Enable and start the service
systemctl daemon-reload
systemctl enable exchange-monitor
systemctl start exchange-monitor

# Install CloudWatch agent (optional)
wget https://amazoncloudwatch-agent.s3.amazonaws.com/ubuntu/amd64/latest/amazon-cloudwatch-agent.deb
dpkg -i amazon-cloudwatch-agent.deb

# Create CloudWatch config
cat > /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json << 'EOF'
{
    "logs": {
        "logs_collected": {
            "files": {
                "collect_list": [
                    {
                        "file_path": "/var/log/exchange-monitor.log",
                        "log_group_name": "exchange-monitor",
                        "log_stream_name": "exchange-monitor-log"
                    }
                ]
            }
        }
    }
}
EOF

# Log completion
echo "✅ Exchange Rate Monitor setup completed at $(date)" >> /var/log/exchange-monitor.log
echo "🎯 Target rate: ${target_rate} TWD per USD" >> /var/log/exchange-monitor.log
echo "📧 Notifications will be sent to: b95702041@gmail.com" >> /var/log/exchange-monitor.log