# OpenHands AWS Infrastructure with Terraform

Deploy OpenHands AI coding assistant on AWS EC2 with Bedrock integration.

## Prerequisites

- **AWS CLI v2** installed (verify with `aws --version`)
- **Terraform** installed (verify with `terraform --version`)
- **AWS Bedrock model access** approved (go to AWS Bedrock Console → Model Access → Request access for required models)

## Quick Start

### 1. Clone Repository
```bash
git clone https://github.com/YangKuoshih/Openhands_Launcher_Using_Terraform_on_AWS_Cloud.git
cd Openhands_Launcher_Using_Terraform_on_AWS_Cloud
```

### 2. First Time Setup
```bash
START-HERE.bat
```
This will automatically:
- Set up AWS SSO authentication (opens browser)
- Deploy OpenHands infrastructure
- Provide access URL

### 3. Daily Usage
```bash
launcher.bat
```
Use this for all daily operations (start/stop instance, open OpenHands, SSH access).

## Configure OpenHands LLM

When you first open OpenHands, configure the AI model:

1. Click "see advanced settings" (small text on popup) or gear icon at bottom left
2. Go to LLM tab and enable "Advanced" toggle
3. Enter these settings:
   - **Custom Model**: `litellm_proxy/Claude4`
   - **Base URL**: `http://litellm`
   - **API Key**: `openhands-key-2024`
4. Click "Save Changes"
5. Complete privacy preferences popup

**Available Models:**
- `Claude3` - Claude 3 Haiku
- `Claude3.7` - Claude 3.7 Sonnet  
- `Claude4` - Claude 4 Sonnet
- `ClaudeOpus4.1` - Claude Opus 4.1
- `NovaPro1` - Amazon Nova Pro

## Troubleshooting

**Model Not Working?** Some Bedrock models need `us.` prefix:
- Check AWS Bedrock Console → Model Access
- If you see "Cross-region inference" → use `us.` prefix in model config
- If no "Cross-region inference" → no prefix needed

## Cleanup
```bash
terraform destroy
```

## Cost Optimization
- **Auto-scheduling**: Runs 8 AM - 10 PM EST (saves ~58% costs)
- **Estimated cost**: ~$17/month with scheduling vs $36/month 24/7

## License
MIT License - feel free to use and modify for your needs.