#!/bin/bash

# Mission DB007 - EC2 User Data Script
# Automated setup for DB007 workspace environment

# Log all output
exec > >(tee /var/log/user-data.log)
exec 2>&1

echo "Starting Mission DB007 workspace setup..."
echo "Timestamp: $(date)"

# Update system
echo "Updating system packages..."
yum update -y

# Install essential packages
echo "Installing essential packages..."
yum install -y \
    python3 \
    python3-pip \
    git \
    jq \
    postgresql \
    htop \
    tree \
    wget \
    curl \
    unzip

# Install AWS CLI v2 (if not already installed)
echo "Installing AWS CLI v2..."
if ! command -v aws &> /dev/null; then
    curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
    unzip awscliv2.zip
    ./aws/install
    rm -rf aws awscliv2.zip
fi

# Create db007 user for the mission
echo "Creating db007 user..."
useradd -m -s /bin/bash db007
usermod -aG wheel db007

# Setup DB007 workspace directory
echo "Setting up workspace directory..."
mkdir -p /home/db007/mission
chown db007:db007 /home/db007/mission

# Clone the mission repository (if URL is provided via tags or metadata)
# This would be customized based on where the repo is hosted
echo "Setting up mission files..."
cd /home/db007/mission

# Create a welcome script
cat > /home/db007/welcome.sh << 'EOF'
#!/bin/bash
echo "=========================================="
echo "    Welcome to Mission DB007 Workspace"
echo "=========================================="
echo ""
echo "Agent DB007 workspace is ready for operation!"
echo ""
echo "Quick Start:"
echo "1. cd ~/mission"
echo "2. Copy your mission files here"
echo "3. Configure application/.env with RDS endpoint"
echo "4. Run: python3 application/db007-agent.py"
echo ""
echo "Useful commands:"
echo "- aws --version          # Check AWS CLI"
echo "- python3 --version     # Check Python"
echo "- psql --version        # Check PostgreSQL client"
echo ""
echo "Mission files should be in: ~/mission/"
echo "Logs location: /var/log/user-data.log"
echo ""
echo "Agent DB007 standing by for orders..."
echo "=========================================="
EOF

chmod +x /home/db007/welcome.sh
chown db007:db007 /home/db007/welcome.sh

# Add welcome message to .bashrc
echo "" >> /home/db007/.bashrc
echo "# Mission DB007 welcome" >> /home/db007/.bashrc
echo "~/welcome.sh" >> /home/db007/.bashrc

# Install Python packages that might be needed
echo "Installing Python packages..."
pip3 install --upgrade pip
pip3 install \
    boto3 \
    psycopg2-binary \
    python-dotenv \
    structlog \
    requests \
    colorama

# Setup CloudWatch agent (optional, for advanced monitoring)
echo "Installing CloudWatch agent..."
wget https://s3.amazonaws.com/amazoncloudwatch-agent/amazon_linux/amd64/latest/amazon-cloudwatch-agent.rpm
rpm -U ./amazon-cloudwatch-agent.rpm
rm -f ./amazon-cloudwatch-agent.rpm

# Create a basic CloudWatch agent config
mkdir -p /opt/aws/amazon-cloudwatch-agent/etc
cat > /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json << 'EOF'
{
    "logs": {
        "logs_collected": {
            "files": {
                "collect_list": [
                    {
                        "file_path": "/var/log/user-data.log",
                        "log_group_name": "/aws/db007/user-data",
                        "log_stream_name": "{instance_id}"
                    }
                ]
            }
        }
    },
    "metrics": {
        "namespace": "DB007/EC2",
        "metrics_collected": {
            "cpu": {
                "measurement": [
                    "cpu_usage_idle",
                    "cpu_usage_iowait",
                    "cpu_usage_user",
                    "cpu_usage_system"
                ],
                "metrics_collection_interval": 60
            },
            "disk": {
                "measurement": [
                    "used_percent"
                ],
                "metrics_collection_interval": 60,
                "resources": [
                    "*"
                ]
            },
            "mem": {
                "measurement": [
                    "mem_used_percent"
                ],
                "metrics_collection_interval": 60
            }
        }
    }
}
EOF

# Set proper permissions
chown -R db007:db007 /home/db007/

# Create a mission info file
cat > /home/db007/mission-info.txt << 'EOF'
Mission DB007 - EC2 Workspace Information
=========================================

Instance Setup Complete!

What's Installed:
- Python 3 + pip
- AWS CLI v2
- PostgreSQL client
- Git, jq, and other utilities
- CloudWatch agent (configured)

Python Packages Installed:
- boto3 (AWS SDK)
- psycopg2-binary (PostgreSQL driver)
- python-dotenv (Environment management)
- structlog (Structured logging)
- requests, colorama

Next Steps:
1. Upload your mission files to ~/mission/
2. Configure application/.env with your RDS endpoint
3. Run the DB007 agent: python3 application/db007-agent.py

Security Notes:
- This instance has the DB007 workspace IAM role attached
- CloudWatch agent is configured for monitoring
- PostgreSQL client is ready for database connections

Happy hunting, Agent DB007!
EOF

chown db007:db007 /home/db007/mission-info.txt

# Start CloudWatch agent
echo "Starting CloudWatch agent..."
/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
    -a fetch-config \
    -m ec2 \
    -c file:/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json \
    -s

# Final setup message
echo "=========================================="
echo "Mission DB007 workspace setup completed!"
echo "Timestamp: $(date)"
echo "=========================================="
echo ""
echo "Summary:"
echo "- System updated and essential packages installed"
echo "- Python 3 and required packages ready"
echo "- AWS CLI v2 configured"
echo "- PostgreSQL client available"
echo "- CloudWatch agent running"
echo "- User 'db007' created with workspace ready"
echo ""
echo "The workspace is ready for Agent DB007!"
echo "=========================================="

# Create a completion flag
touch /var/log/user-data-complete
echo "User data script completed successfully" > /var/log/user-data-complete