# OpenHands AWS Infrastructure

Complete Terraform setup for OpenHands on AWS with auto-scheduling and command shortcuts.

## Quick Start

1. **Setup shortcuts** (one-time):
   ```
   cd scripts
   setup-shortcuts.bat
   ```
   Then restart your command prompt.

2. **Deploy infrastructure**:
   ```
   tfa
   ```

3. **Access OpenHands**:
   ```
   oh
   ```

## Available Commands

| Command | Description |
|---------|-------------|
| `tfa` | Deploy/Update infrastructure (terraform init + apply) |
| `tfd` | Destroy infrastructure |
| `tfp` | Plan infrastructure changes |
| `ec2` | SSH to EC2 instance |
| `oh` | Open OpenHands in browser |
| `status` | Show infrastructure status |
| `ec2start` | Manually start EC2 instance |
| `ec2stop` | Manually stop EC2 instance |

## Infrastructure Details

### Resources Created
- **VPC** with public/private subnets
- **EC2 instance** (t3.medium) with OpenHands
- **Security Groups** for SSH and web access
- **Lambda functions** for auto start/stop
- **EventBridge rules** for scheduling
- **IAM roles** with proper permissions

### Auto-Scheduling
- **Start**: 8 AM EST daily
- **Stop**: 10 PM EST daily
- **Cost savings**: ~58% (10 hours/day vs 24/7)

### Configuration
All settings are in `config.json`:
- Instance type and region
- Network CIDR blocks
- Schedule times
- OpenHands version

## OpenHands Configuration

Once deployed, configure OpenHands:

1. Open: `http://[EC2-IP]:8150`
2. Click gear icon (⚙️) → LLM tab
3. Set:
   - **Custom Model**: `litellm_proxy/Claude4`
   - **Base URL**: `http://litellm`
   - **API Key**: `openhands-key-2024`

## Security

- SSH key pair auto-generated
- Security groups restrict access to SSH (22) and OpenHands (8150)
- AWS credentials read from `~/.aws/credentials`
- No credentials stored in Terraform files

## Cost Estimate

- **EC2 t3.medium**: ~$0.05/hour
- **Running 10 hours/day**: ~$15/month
- **Storage (EBS)**: ~$2/month
- **Total**: ~$17/month

## Troubleshooting

- **SSH issues**: Ensure `openhands-key` file exists
- **Access issues**: Check security groups and instance state
- **OpenHands not loading**: Wait 2-3 minutes after instance start
- **AWS errors**: Verify credentials in `~/.aws/credentials`

## Files Structure

```
terraform/
├── config.json          # Configuration parameters
├── main.tf              # VPC, EC2, security groups
├── lambda.tf            # Auto start/stop functions
├── eventbridge.tf       # Scheduling rules
├── iam.tf               # IAM roles and policies
├── outputs.tf           # Infrastructure outputs
├── user-data.sh         # EC2 setup script
└── scripts/
    ├── setup-shortcuts.bat
    ├── tfa.bat
    ├── tfd.bat
    ├── ec2.bat
    ├── oh.bat
    └── status.bat
```