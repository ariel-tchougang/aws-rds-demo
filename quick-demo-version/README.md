# Mission DB007 - Quick Demo Version

**Quick version** for experienced users - AWS RDS Multi-AZ demonstration in 5 minutes!

⚠️ **SECURITY WARNING**: This version uses public subnets and public RDS access for demo simplicity. **DO NOT use in production!**

🔒 **Production Ready?** Use the [Full Version](../README.md) with private subnets and proper security.

## 🎯 Objectives

- **RPO = 0**: Data continuity verification
- **RTO < 2 minutes**: Precise recovery time measurement  
- **Automatic detection**: Server fingerprint + AZ tracking
- **Ultra-fast setup**: 5 minutes instead of 20 minutes

## 🚀 Quick Start (5 minutes)

> 💼 **For production or learning best practices?** Use the [Full Version](../README.md) with private subnets, EC2/Cloud9 workspace, and enterprise security.

### 1. Prerequisites

**On your local PC:**
- **Python 3.7+**: [Download Python](https://www.python.org/downloads/)
- **AWS CLI**: [Install AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html)
- **Git**: [Download Git](https://git-scm.com/downloads)

**Or use AWS CloudShell** (Python and AWS CLI already installed)

### 2. AWS Configuration

```bash
# Configure your AWS credentials
aws configure
```

### 3. Infrastructure Deployment

**Option A: CloudFormation**
```bash
cd cloudformation
cp config.env.example config.env
# Edit config.env with your parameters
./deploy.sh
```

**Option B: Terraform**
```bash
cd terraform
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your parameters
./deploy.sh
```

### 4. Application Configuration

```bash
cd application

# Windows PowerShell
.\setup.ps1

# Linux/macOS/CloudShell
./setup.sh
```

### 5. Launch

```bash
# Edit .env with RDS endpoint (displayed after deployment)
nano .env

# Start the demonstration
demo-start
```

### 6. Failover Test

```bash
# In another terminal
demo-failover
```

## 🔧 Secure Configuration

### IP Access Restriction

**To secure access, replace in your configuration:**

```bash
# Instead of (worldwide access - DANGEROUS)
CLIENT_ACCESS_CIDR="0.0.0.0/0"

# Use your IP (secure)
CLIENT_ACCESS_CIDR="203.0.113.42/32"
```

**Find your IP:** [whatismyipaddress.com](https://whatismyipaddress.com/)

### CloudShell

If using AWS CloudShell, keep `0.0.0.0/0` as CloudShell IPs change frequently.

## 💰 Cost Breakdown

### Daily Demo Costs (us-east-1 region)

#### Core Infrastructure
| Service | Configuration | Daily Cost | Notes |
|---------|---------------|------------|-------|
| **RDS PostgreSQL** | db.t3.micro Multi-AZ | ~$0.83 | Primary + standby instances |
| **RDS Storage** | 20 GB gp3 Multi-AZ | ~$0.13 | 2x storage (primary + standby) |
| **VPC** | Standard VPC | $0.00 | No charge for VPC itself |
| **Public Subnets** | 2 subnets | $0.00 | No NAT Gateway needed |
| **Internet Gateway** | Standard | $0.00 | Direct internet access |
| **Security Groups** | RDS + application | $0.00 | No charge |

#### Monitoring & Logging
| Service | Usage | Daily Cost | Notes |
|---------|-------|------------|-------|
| **CloudWatch Metrics** | Custom metrics | ~$0.10 | DB007/Mission namespace |
| **CloudWatch Logs** | Application logs | ~$0.07 | Structured JSON logs |
| **CloudWatch Dashboard** | 1 dashboard | ~$0.10 | RDS + application metrics |

#### Workspace Options
| Option | Cost | Daily Cost | Notes |
|--------|------|------------|-------|
| **Local PC** | Free | $0.00 | Run agent locally |
| **AWS CloudShell** | Free | $0.00 | 1GB storage included |
| **EC2 (optional)** | t3.micro + 10GB gp3 | ~$0.30 | If you prefer cloud workspace |

### Total Daily Demo Costs

#### Minimal Cost (Recommended)
- RDS Multi-AZ + Storage: **$0.96**
- CloudWatch: **$0.27**
- Local PC workspace: **$0.00**
- **Total: ~$1.23/day**

#### With Cloud Workspace
- RDS Multi-AZ + Storage: **$0.96**
- CloudWatch: **$0.27**
- EC2 workspace: **$0.30**
- **Total: ~$1.53/day**

#### Minimal Monitoring
- RDS Multi-AZ + Storage: **$0.96**
- Basic CloudWatch: **$0.10**
- Local PC workspace: **$0.00**
- **Total: ~$1.06/day**

**Recommendation**: Use us-east-1 or us-west-2 for lowest costs.

## 📊 Differences vs Full Version

| Aspect | Full Version | Quick Demo |
|--------|--------------|------------|
| **Security** | Private subnets + NAT | Public subnets |
| **RDS Access** | Private only | Public (configurable) |
| **Workspace** | EC2/Cloud9 required | Local PC or CloudShell |
| **Setup** | 15-20 minutes | 5 minutes |
| **Daily Cost** | ~$1.53 | ~$1.23 |
| **Production** | ✅ Ready | ❌ Demo only |

## 🎮 Available Commands

```bash
demo-activate   # Activate Python environment
demo-start      # Start DB007 agent
demo-status     # Check RDS status
demo-failover   # Trigger controlled failover
```

## 📈 Expected Results

```
==================== DB007 MISSION REPORT ====================
Start writer_fingerprint : 10.0.1.123:5432 pg15.4@db007-mission-postgres.xyz.rds.amazonaws.com
Start primary AZ         : us-east-1a
End writer_fingerprint   : 10.0.2.234:5432 pg15.4@db007-mission-postgres.xyz.rds.amazonaws.com
End primary AZ           : us-east-1b
Total writes             : 1247
Total reads              : 623
Estimated downtime (s)   : 67.45
RPO = 0 confirmed        : YES (sample: [1247, 1246, 1245, 1244, 1243]...)
Writer changed           : YES 🛰️ (failover observed)
AZ changed               : YES (Multi-AZ failover)
===============================================================

Mission accomplished. License to query remains valid. 🕶️
```

## 🧹 Cleanup

```bash
# CloudFormation
cd cloudformation
./undeploy.sh

# Terraform
cd terraform
./undeploy.sh
```

## ⚠️ Security Warnings

1. **Public RDS**: Database accessible from Internet
2. **Public subnets**: No NAT Gateway, direct access
3. **Demo only**: Never use this configuration in production
4. **IP restriction**: Always limit access to your IP when possible

## 🔄 Migration to Full Version

To switch to the secure full version:

1. Delete this infrastructure: `./undeploy.sh`
2. Use the full version in the parent directory
3. Deploy with private subnets and EC2/Cloud9

## 📚 Complete Documentation

- [Full Version](../README.md) - Secure setup with EC2/Cloud9
- [Mission Brief EN](mission-multi-az-en.md) - Detailed steps
- [Mission Brief FR](mission-multi-az-fr.md) - French guide

---

> *"Quick demo accomplished. For production, use the secure version... Agent DB007 recommends proper security."* 🕶️⚡

**Agent DB007** - *Elite Database Consultant (Quick Mode)*