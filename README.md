# OpenHands AWS Infrastructure with Terraform

Deploy OpenHands AI coding assistant on AWS EC2 with Bedrock integration.

## Prerequisites

- **AWS CLI v2** installed (verify with `aws --version`)
- **Terraform** installed (verify with `terraform --version`)
- **AWS Bedrock model access** approved (go to AWS Bedrock Console → Model Access → Request access for required models)

## Configuration

On first run, `START-HERE.bat` will automatically create configuration files from examples:
- `terraform/config.json` - Infrastructure settings
- `terraform/scripts/aws_sso_helper/config.ini` - AWS SSO configuration

Edit `config.ini` with your AWS SSO start URL if using SSO authentication.

## Quick Start

### 1. Clone Repository
```bash
git clone https://github.com/YangKuoshih/Openhands_Launcher_Using_Terraform_on_AWS_Cloud.git
cd Openhands_Launcher_Using_Terraform_on_AWS_Cloud
```

### 2. First Time Setup
```cmd
START-HERE.bat
```
This will automatically:
- Check AWS credentials (set up SSO if needed)
- Check for existing infrastructure and give you options
- Deploy OpenHands infrastructure
- Provide access URL

### 3. Daily Usage
```cmd
launcher.bat
```
**Important:** Use `launcher.bat` (not `launch.bat`) for all daily operations:

**Launcher Options:**
1. **oh** - Open OpenHands in browser
2. **ec2** - SSH to EC2 instance  
3. **status** - Refresh status (restart launcher)
4. **ec2start** - Manually start EC2 instance
5. **ec2stop** - Manually stop EC2 instance
6. **tfp** - Plan infrastructure changes
7. **tfa** - Update infrastructure and OpenHands containers
8. **tfd** - Destroy infrastructure
9. **cleanup** - Fix resource conflicts
10. **Exit** - Close launcher

## Docker Image Versions

This deployment uses **latest versions** of OpenHands for newest features:
- OpenHands: `docker.all-hands.dev/all-hands-ai/openhands:latest`
- Runtime: `docker.all-hands.dev/all-hands-ai/runtime:latest`
- LiteLLM: `ghcr.io/berriai/litellm:main-latest`

**To use pinned versions:** Edit `terraform/user-data.sh` and change version tags to specific versions (e.g., `0.53`)

## Configure OpenHands LLM

When you first open OpenHands, configure the AI model:

1. Click "see advanced settings" (small text on popup) or gear icon at bottom left
2. Go to LLM tab and enable "Advanced" toggle
3. Enter these settings:
   - **Custom Model**: `litellm_proxy/Claude4`
   - **Base URL**: `http://litellm`
   - **API Key**: `openhands-key-2025`
4. Click "Save Changes"
5. Complete privacy preferences popup

**Available Models:**
- `Claude3` - Claude 3 Haiku
- `Claude3.7` - Claude 3.7 Sonnet  
- `Claude4` - Claude 4 Sonnet
- `ClaudeOpus4.1` - Claude Opus 4.1
- `NovaPro1` - Amazon Nova Pro

## Resource Conflicts & Cleanup

**When you see "already exists" errors:**
```
openhands-aws-setup-openhands-policy already exists
openhands-key already exists
openhands-aws-setup-scheduler-role already exists
```

**What cleanup does:**
- Imports existing AWS resources into Terraform state
- Allows Terraform to manage resources it created previously
- **Safe operation** - never deletes or modifies existing infrastructure
- Fixes state mismatches between Terraform and AWS

**When to run cleanup:**
- After interrupting a previous Terraform deployment
- When switching between different Terraform state files
- If you see "resource already exists" errors during `terraform apply`
- When Terraform "forgets" about resources it previously created

**How to run cleanup:**
```cmd
launcher.bat
```
Select option 9 (cleanup), then option 7 (tfa) to apply changes.

## Troubleshooting

**Model Not Working?** Some Bedrock models need `us.` prefix:
- Check AWS Bedrock Console → Model Access
- If you see "Cross-region inference" → use `us.` prefix in model config
- If no "Cross-region inference" → no prefix needed

**Resource Conflicts?** See [TROUBLESHOOTING.md](TROUBLESHOOTING.md) for detailed solutions.

## Cleanup
```cmd
launcher.bat
```
Select option 8 (tfd) to destroy all infrastructure

## Cost Optimization
- **Auto-scheduling**: Runs 8 AM - 10 PM EST (saves ~58% costs)
- **Estimated cost**: ~$17/month with scheduling vs $36/month 24/7

## License
MIT License - feel free to use and modify for your needs.