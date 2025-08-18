# OpenHands AWS Infrastructure with Terraform

Complete AWS infrastructure setup for OpenHands AI coding assistant with automated scheduling, cost optimization, and AWS Bedrock integration.

## 🏗️ Infrastructure Overview

This Terraform script creates a complete AWS environment for running OpenHands with the following components:

### Core Infrastructure
- **Custom VPC** (`10.0.0.0/16`) with public/private subnets
- **EC2 Instance** (t3.medium, 2 vCPU, 4GB RAM) with Amazon Linux 2
- **Elastic IP** for consistent public access
- **Security Groups** restricting access to your IP only
- **SSH Key Pair** auto-generated for secure access

### Networking & Security
- **Internet Gateway** for public internet access
- **Route Tables** for proper traffic routing
- **Security Group Rules**:
  - SSH (port 22) - restricted to your IP
  - OpenHands web (port 8150) - restricted to your IP
  - All outbound traffic allowed

### IAM & Permissions
- **EC2 Instance Role** with permissions for:
  - Full AWS Bedrock access (`bedrock:*`)
  - S3 object read/write
  - SSM parameter access
- **EventBridge Scheduler Role** for auto start/stop

### Auto-Scheduling (Cost Optimization)
- **Start Schedule**: 8:00 AM EST daily (`cron(0 13 * * ? *)`)
- **Stop Schedule**: 10:00 PM EST daily (`cron(0 3 * * ? *)`)
- **Cost Savings**: ~58% reduction (estimated $17/month vs $36/month 24/7)

### OpenHands Configuration
- **Docker Compose** setup with:
  - OpenHands container (port 8150)
  - LiteLLM proxy for AWS Bedrock integration
- **Pre-configured AI Models**:
  - Claude 3 Haiku
  - Claude 3.7 Sonnet
  - Claude 4 Sonnet
  - Claude Opus 4.1
  - Amazon Nova Pro

## 📋 Prerequisites

1. **AWS CLI** configured with valid credentials
2. **Terraform** installed (version 5.0+)
3. **Git** for cloning the repository
4. **AWS Account** with Bedrock model access

## 🚀 Quick Start

### 1. Clone Repository
```bash
git clone <your-repo-url>
cd openhands-setup-and-learn/terraform/scripts
```

### 2. Setup Environment
```bash
setup-shortcuts.bat
```
This creates command shortcuts for easy management.

### 3. Deploy Infrastructure
```bash
tfa
```
This runs `terraform apply` and creates all AWS resources.

### 4. Access OpenHands
```bash
oh
```
Opens OpenHands in your browser at `http://<elastic-ip>:8150`

## 🛠️ Available Commands

| Command | Description | Full Command |
|---------|-------------|--------------|
| `tfa` | Deploy/update infrastructure | `terraform apply -auto-approve` |
| `tfd` | Destroy all infrastructure | `terraform destroy -auto-approve` |
| `tfp` | Preview changes | `terraform plan` |
| `ec2` | SSH to EC2 + start Docker | SSH connection with container startup |
| `oh` | Open OpenHands in browser | Opens web interface |
| `status` | Show infrastructure status | Display instance state and URLs |
| `ec2start` | Manually start EC2 | Force start the instance |
| `ec2stop` | Manually stop EC2 | Force stop the instance |

## ⚙️ Configuration

### Main Configuration (`config.json`)
```json
{
  "project": {
    "id": "openhands-tony-2024",
    "name": "OpenHands Tony 2024", 
    "owner": "tony.yang"
  },
  "aws": {
    "region": "us-east-1",
    "instance_type": "t3.medium",
    "availability_zone": "us-east-1a"
  },
  "schedule": {
    "start_time": "cron(0 13 * * ? *)",  // 8 AM EST
    "stop_time": "cron(0 3 * * ? *)"     // 10 PM EST
  }
}
```

### OpenHands LLM Configuration
After deployment, configure in OpenHands UI:
- **Model**: `Claude4` (or `Claude3`, `NovaPro1`, `Claude3.7`, `ClaudeOpus4.1`)
- **Base URL**: `http://litellm`
- **API Key**: `openhands-key-2024`

## 🔒 Security Features

### Network Security
- **VPC Isolation**: Custom VPC separate from default
- **IP Restrictions**: Access limited to your current public IP
- **Security Groups**: Minimal required ports only

### Access Control
- **SSH Key Authentication**: Auto-generated 4096-bit RSA keys
- **IAM Roles**: Least-privilege permissions
- **No Hardcoded Credentials**: Uses AWS instance profiles

### Data Protection
- **Encrypted Storage**: GP3 volumes with encryption
- **Secure Metadata**: IMDSv2 required
- **Private Keys**: Excluded from Git via `.gitignore`

## 💰 Cost Breakdown

### Monthly Estimates (us-east-1)
- **EC2 t3.medium**: ~$30/month (24/7) → ~$13/month (14 hours/day)
- **EBS GP3 20GB**: ~$2/month
- **Elastic IP**: ~$3.65/month
- **Data Transfer**: ~$1/month
- **Total**: ~$17/month with auto-scheduling

### Cost Optimization Features
- **Auto-scheduling**: 58% cost reduction
- **GP3 storage**: More cost-effective than GP2
- **Right-sized instance**: t3.medium balances performance/cost
- **Elastic IP**: Prevents IP changes and associated costs

## 🔧 Troubleshooting

### Common Issues

**"Cannot get instance IP"**
```bash
# Solution: Deploy infrastructure first
tfa
```

**"SSH connection failed"**
```bash
# Check instance status
status
# Ensure your IP hasn't changed (security group restriction)
```

**"OpenHands not loading"**
```bash
# Wait 2-3 minutes after instance start
# Check containers are running
ec2
docker ps
```

**"AWS credentials expired"**
```bash
# Update ~/.aws/credentials with fresh tokens
# Only affects local Terraform commands, not the running infrastructure
```

### Debugging Commands
```bash
# Check instance state
aws ec2 describe-instances --instance-ids <instance-id>

# View container logs
docker logs openhands-app
docker logs litellm

# Test LiteLLM health
curl http://litellm/health
```

## 📁 Project Structure

```
openhands-setup-and-learn/
├── README.md                    # This documentation
├── .gitignore                   # Excludes sensitive files
├── terraform/
│   ├── config.json             # Main configuration
│   ├── main.tf                 # Core infrastructure
│   ├── outputs.tf              # Terraform outputs
│   ├── user-data.sh            # EC2 initialization script
│   ├── keys/                   # SSH keys (auto-generated)
│   │   ├── openhands-key.pem   # Private key
│   │   └── openhands-key.pub   # Public key
│   └── scripts/                # Management scripts
│       ├── setup-shortcuts.bat # Setup command aliases
│       ├── tfa.bat             # Terraform apply
│       ├── tfd.bat             # Terraform destroy
│       ├── ec2.bat             # SSH connection
│       ├── oh.bat              # Open OpenHands
│       └── status.bat          # Infrastructure status
```

## 🔄 Automated Processes

### Instance Lifecycle
1. **Daily Start** (8 AM EST): EventBridge triggers EC2 start
2. **Boot Process**: 
   - Docker service starts
   - OpenHands containers launch via systemd service
   - LiteLLM connects to AWS Bedrock
3. **Daily Stop** (10 PM EST): EventBridge triggers EC2 stop

### Container Management
- **Auto-restart**: Systemd service ensures containers start on boot
- **Health monitoring**: LiteLLM health checks for model availability
- **Persistent data**: OpenHands workspace persists across restarts

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Test changes with `tfp` (terraform plan)
4. Submit a pull request

## 📄 License

MIT License - feel free to use and modify for your needs.

## 🙏 Acknowledgments

- [OpenHands](https://github.com/All-Hands-AI/OpenHands) - AI coding assistant
- [LiteLLM](https://github.com/BerriAI/litellm) - LLM proxy for AWS Bedrock
- [Terraform](https://terraform.io) - Infrastructure as Code
- [AWS](https://aws.amazon.com) - Cloud infrastructure platform