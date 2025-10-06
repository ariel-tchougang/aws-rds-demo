# Mission DB007 - Multi-AZ RDS Demonstration

**Agent DB007**, elite IT consultant, demonstrates AWS RDS Multi-AZ resilience for **DataCorp**.

📋 **Mission Briefs:** [English](mission-multi-az-en.md) | [Français](mission-multi-az-fr.md)

⚡ **Quick Demo:** Want a 5-minute setup? Try the [Quick Demo Version](quick-demo-version/) (public subnets, local PC)

## 🎯 Mission Objective

Prove that AWS RDS Multi-AZ deployment achieves:
- **RPO = 0** (no data loss)
- **RTO < 2 minutes** (minimal downtime)
- **Automatic failover** without manual intervention

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                        VPC (10.0.0.0/16)                   │
│                                                             │
│  ┌─────────────────┐              ┌─────────────────┐      │
│  │   AZ-1 (us-east-1a)           │   AZ-2 (us-east-1b)    │
│  │                 │              │                 │      │
│  │  ┌─────────────┐│              │┌─────────────┐  │      │
│  │  │Public Subnet││              ││Public Subnet│  │      │
│  │  │10.0.1.0/24  ││              ││10.0.2.0/24  │  │      │
│  │  └─────────────┘│              │└─────────────┘  │      │
│  │                 │              │                 │      │
│  │  ┌─────────────┐│              │┌─────────────┐  │      │
│  │  │Private Sub. ││              ││Private Sub.  │  │      │
│  │  │10.0.10.0/24 ││              ││10.0.11.0/24 │  │      │
│  │  │             ││              ││             │  │      │
│  │  │ [PRIMARY]   ││    ←→        ││ [STANDBY]   │  │      │
│  │  │ PostgreSQL  ││ Sync Replica ││ PostgreSQL  │  │      │
│  │  └─────────────┘│              │└─────────────┘  │      │
│  └─────────────────┘              └─────────────────┘      │
└─────────────────────────────────────────────────────────────┘
```

## 📁 Project Structure

```
aws-rds-demo/
├── README.md                    # This file
├── mission-multi-az-fr.md       # French mission brief
├── mission-multi-az-en.md       # English mission brief
├── .gitignore                   # Git ignore file
│
├── cloudformation/              # CloudFormation deployment
│   ├── db007-infrastructure.yaml   # Main infrastructure template
│   ├── db007-monitoring.yaml       # CloudWatch monitoring
│   ├── config.env.example          # Configuration template
│   ├── deploy.sh                   # Linux/macOS deployment
│   ├── deploy.ps1                  # Windows PowerShell deployment
│   ├── undeploy.sh                 # Linux/macOS cleanup
│   └── undeploy.ps1                # Windows PowerShell cleanup
│
├── terraform/                   # Terraform deployment
│   ├── main.tf                     # Main Terraform configuration
│   ├── variables.tf                # Input variables
│   ├── outputs.tf                  # Output values
│   ├── vpc.tf                      # VPC and networking
│   ├── rds.tf                      # RDS Multi-AZ configuration
│   ├── monitoring.tf               # CloudWatch resources
│   ├── terraform.tfvars.example    # Variables template
│   ├── deploy.sh                   # Linux/macOS deployment
│   ├── deploy.ps1                  # Windows PowerShell deployment
│   ├── undeploy.sh                 # Linux/macOS cleanup
│   └── undeploy.ps1                # Windows PowerShell cleanup
│
├── application/                 # DB007 monitoring agent
│   ├── main.py                     # Main application entry point
│   ├── loops.py                    # Traffic generation loops
│   ├── requirements.txt            # Python dependencies
│   ├── .env.example                # Environment template
│   ├── setup.sh                    # Application setup script
│   ├── check-rds.sh                # RDS status check
│   ├── trigger-failover.sh         # Failover trigger script
│   ├── README.md                   # Application documentation
│   └── utils/                      # Utility modules
│       ├── __init__.py             # Python package init
│       ├── aws.py                  # AWS service interactions
│       ├── config.py               # Configuration management
│       ├── database.py             # DB operations with failover detection
│       ├── loops.py                # Traffic generation utilities
│       └── state.py                # Application state management
│
├── scripts/                     # Infrastructure scripts
│   └── user-data.sh                # EC2 instance setup script
│
└── quick-demo-version/          # Quick demo variant (public subnets)
    ├── README.md                   # Quick demo documentation
    ├── mission-multi-az-en.md      # English mission brief
    ├── mission-multi-az-fr.md      # French mission brief
    ├── cloudformation/             # CloudFormation for quick demo
    ├── terraform/                  # Terraform for quick demo
    ├── application/                # Application for quick demo
    └── scripts/                    # Quick demo scripts
```

## 🚀 Quick Start

> 💡 **New to AWS or want faster setup?** Consider the [Quick Demo Version](quick-demo-version/) - 5 minutes setup from your local PC instead of 20 minutes with EC2/Cloud9.

### 1. Mission Setup

```bash
# Clone and setup
git clone <repository>
cd aws-rds-demo
```

### 2. Configure Settings

**For Terraform:**
```bash
cp terraform/terraform.tfvars.example terraform/terraform.tfvars
# Edit terraform/terraform.tfvars with your AWS settings
```

**For CloudFormation:**
```bash
cp cloudformation/config.env.example cloudformation/config.env
# Edit cloudformation/config.env with your AWS settings
```

### 3. Deploy Infrastructure

**Terraform:**
```bash
cd terraform
./deploy.sh
```

**CloudFormation:**
```bash
cd cloudformation
./deploy.sh
```

### 4. Setup Workspace Environment

Since the RDS instance is in private subnets, you need a workspace to run the DB007 agent:

**Option A: EC2 Instance (Recommended)**
1. Create an EC2 instance in one of the public subnets
2. Use the provided IAM instance profile: `{project-name}-workspace-profile`
3. Use security group: `{project-name}-app-sg`
4. **Optional**: Use the provided user-data script: `scripts/user-data.sh`
5. SSH to the instance and upload the `application/` folder
6. Run: `cd /path/to/application && chmod u+x *.sh`
7. Run: `./setup.sh`

**Option B: Cloud9 Environment**
1. Create Cloud9 environment in the VPC
2. Choose one of the public subnets
3. Attach the workspace IAM role
4. Upload the `application/` folder
5. Run: `cd /path/to/application && chmod u+x *.sh`
6. Run: `./setup.sh`

### 5. Configure Application

```bash
# Get RDS endpoint and update configuration
./scripts/check-rds.sh

```

### 6. Start Mission

```bash
# Activate environment and start agent
demo-activate
python db007-agent.py

# Or use the convenience alias
demo-start
```

### 7. Execute Failover Test

```bash
# In another terminal
demo-failover

# Or check status first
demo-status
```

## 🔧 Prerequisites

- **AWS CLI** configured with appropriate permissions
- **Python 3.7+** with pip and venv
- **Terraform 1.0+** (if using Terraform deployment)
- **jq** (recommended for status checks)
- **Git** (for cloning repository)

### Required AWS Permissions

- RDS: Full access for Multi-AZ operations
- VPC: Create/manage networking components
- CloudWatch: Metrics, logs, and dashboards
- IAM: Create roles for monitoring

## 📊 Monitoring & Observability

### CloudWatch Dashboard
- RDS performance metrics (CPU, connections, latency)
- Application metrics (response time, connection status)
- Failover metrics (duration, recovery time)
- Critical events and logs

### Custom Metrics
- `DB007/Mission` namespace
- Database response times by operation
- Connection status tracking
- Failover duration measurement

### Structured Logging
- JSON formatted logs
- CloudWatch Logs integration
- Event correlation and tracing

## 🎮 Mission Execution

> 📖 **Detailed mission steps:** See [Mission Brief (English)](mission-multi-az-en.md) or [Brief de Mission (Français)](mission-multi-az-fr.md)

### 🎮 Available Commands

```bash
demo-activate   # Activate Python environment
demo-start      # Start DB007 agent
demo-status     # Check RDS status
demo-failover   # Trigger controlled failover
```

### Phase 1: Reconnaissance
```bash
demo-status
```
Verify infrastructure status and Multi-AZ configuration.

### Phase 2: Traffic Generation
The DB007 agent continuously:
- Inserts timestamped records
- Performs SELECT queries
- Monitors connection status
- Publishes CloudWatch metrics

```bash
demo-activate

demo-start
```

### Phase 3: Controlled Sabotage
```bash
demo-failover
```
Triggers RDS reboot with failover and monitors:
- Failover initiation
- Connection interruption
- AZ switch
- Recovery completion
- Total RTO measurement

### Phase 4: Validation
- Verify data integrity (no lost records)
- Confirm AZ switch (primary ↔ standby)
- Measure actual RTO vs. target
- Review CloudWatch metrics and logs

## 📈 Expected Results

| Metric | Target | Typical Result |
|--------|--------|----------------|
| **RPO** | 0 | 0 (synchronous replication) |
| **RTO** | < 2 minutes | 60-120 seconds |
| **Data Loss** | None | None |
| **Manual Intervention** | None | None |

## 🧹 Cleanup

```bash
# CloudFormation
cd cloudformation
./undeploy.sh

# Terraform
cd terraform
./undeploy.sh
```

## 🔍 Troubleshooting

### Common Issues

**Connection Failures:**
- Verify security group rules
- Check VPC configuration
- Validate database credentials
- Ensure virtual environment is activated
- Check Python dependencies are installed

**Failover Not Working:**
- Ensure Multi-AZ is enabled
- Check RDS instance status
- Verify AWS permissions

**Metrics Not Appearing:**
- Check IAM role permissions
- Verify CloudWatch agent configuration
- Review application logs

### Debug Commands

```bash
# Check RDS status (from workspace)
demo-status

# Activate virtual environment
demo-activate

# Check CloudWatch metrics
aws cloudwatch list-metrics --namespace "DB007/Mission"

# RDS events
aws rds describe-events --source-identifier db007-mission-postgres
```

## 💰 Cost Breakdown

### Daily Demo Costs (us-east-1 region)

#### Core Infrastructure
| Service | Configuration | Daily Cost | Notes |
|---------|---------------|------------|-------|
| **RDS PostgreSQL** | db.t3.micro Multi-AZ | ~$0.83 | Primary + standby instances |
| **RDS Storage** | 20 GB gp3 Multi-AZ | ~$0.13 | 2x storage (primary + standby) |
| **VPC** | Standard VPC | $0.00 | No charge for VPC itself |
| **Internet Gateway** | Standard | $0.00 | No charge |
| **Security Groups** | Multiple groups | $0.00 | No charge |

#### Monitoring & Logging
| Service | Usage | Daily Cost | Notes |
|---------|-------|------------|-------|
| **CloudWatch Metrics** | Custom metrics | ~$0.10 | DB007/Mission namespace |
| **CloudWatch Logs** | Application logs | ~$0.07 | Structured JSON logs |
| **CloudWatch Dashboard** | 1 dashboard | ~$0.10 | RDS + application metrics |

#### Workspace Options
| Option | Instance Type | Daily Cost | Notes |
|--------|---------------|------------|-------|
| **EC2 (t3.micro)** | 1 instance + 10GB gp3 | ~$0.30 | For running DB007 agent |
| **Cloud9** | t3.small + 10GB gp3 | ~$0.58 | Managed IDE environment |

### Total Daily Demo Costs

#### EC2 Workspace (Recommended)
- RDS Multi-AZ + Storage: **$0.96**
- CloudWatch: **$0.27**
- EC2 Workspace: **$0.30**
- **Total: ~$1.53/day**

#### Cloud9 Workspace
- RDS Multi-AZ + Storage: **$0.96**
- CloudWatch: **$0.27**
- Cloud9 Workspace: **$0.58**
- **Total: ~$1.81/day**

**Recommendation**: Use us-east-1 or us-west-2 for lowest costs.

## 🔐 Security Best Practices

- Database in private subnets only
- Security groups with minimal access
- Encrypted storage enabled
- No hardcoded credentials
- IAM roles with least privilege
- **SSH Access**: Restrict SSH CIDR to your IP (replace `0.0.0.0/0` with `your-ip/32`)
- **Key Management**: Use existing SSH key pairs, don't create new ones in IaC

## 📚 Additional Resources

### Mission Documentation
- [Mission Brief - English](mission-multi-az-en.md) - Detailed mission steps and narrative
- [Brief de Mission - Français](mission-multi-az-fr.md) - Étapes détaillées de la mission

### AWS Documentation
- [AWS RDS Multi-AZ Documentation](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/Concepts.MultiAZ.html)
- [RDS Failover Process](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/Concepts.MultiAZ.html#Concepts.MultiAZ.Failover)
- [CloudWatch Custom Metrics](https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/publishingMetrics.html)

## 🤝 Contributing

1. Fork the repository
2. Create feature branch (`git checkout -b feature/enhancement`)
3. Commit changes (`git commit -am 'Add enhancement'`)
4. Push to branch (`git push origin feature/enhancement`)
5. Create Pull Request

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

---

> *"Mission accomplished. Thanks to AWS RDS Multi-AZ, DataCorp can survive even the trickiest outages... and DB007 keeps his license to query."* 🕶️

**Agent DB007** - *Elite Database Consultant*