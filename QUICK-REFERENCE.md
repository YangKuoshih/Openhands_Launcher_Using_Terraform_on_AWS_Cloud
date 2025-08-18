# OpenHands Quick Reference

## 🚀 First Time Setup
```bash
START-HERE.bat
```

## 📅 Daily Usage
```bash
launcher.bat
```

## 🛠️ Management Commands
| Command | Description |
|---------|-------------|
| `launcher.bat` | Daily launcher (start instance + open OpenHands) |
| `terraform\scripts\tfa.bat` | Deploy/update infrastructure |
| `terraform\scripts\tfd.bat` | Destroy all infrastructure |
| `terraform\scripts\ec2.bat` | SSH to instance |
| `terraform\scripts\status.bat` | Check infrastructure status |

## ⚙️ Configuration Files
- `terraform\config.json` - Main settings (region, instance type, schedule)
- `terraform\scripts\aws_sso_helper\config.ini` - AWS SSO settings

## 🔧 Troubleshooting
- **Can't connect**: Check if your IP changed (security group restriction)
- **OpenHands not loading**: Wait 2-3 minutes after instance start
- **AWS credentials expired**: Run `terraform\scripts\setup-aws-sso.bat`

## 💰 Cost Optimization
- **Auto-schedule**: Runs 8 AM - 10 PM EST (saves ~58% costs)
- **Manual control**: Use `ec2start.bat` and `ec2stop.bat`
- **Estimated cost**: ~$17/month with scheduling

## 🔒 Security
- Access restricted to your IP only
- SSH keys auto-generated and stored in `terraform\keys\`
- AWS Bedrock integration with IAM roles (no hardcoded credentials)