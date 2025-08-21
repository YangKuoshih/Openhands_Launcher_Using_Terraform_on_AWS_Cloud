# Troubleshooting Guide

## Resource Already Exists Errors

If you see errors like:
- `openhands-aws-setup-openhands-policy already exists`
- `openhands-key already exists` 
- `openhands-aws-setup-scheduler-role already exists`

**Solution 1 (Recommended):**
```cmd
launcher.bat
```
Choose option 9 (cleanup) to import existing resources into Terraform.

**Solution 2 (Manual):**
```cmd
cd terraform
cleanup-resources.bat
terraform apply
```

**Solution 3 (Nuclear option):**
If you want to start completely fresh, manually delete the resources in AWS Console:
- IAM → Policies → Delete `openhands-aws-setup-openhands-policy`
- IAM → Roles → Delete `openhands-aws-setup-scheduler-role`  
- EC2 → Key Pairs → Delete `openhands-key`

Then run `terraform apply` again.

## Other Common Issues

**AWS Credentials:**
- Run `aws sts get-caller-identity` to verify credentials
- If failed, run START-HERE.bat to set up SSO

**Terraform State Issues:**
- Delete `.terraform` folder and run `terraform init`
- Check `terraform.tfstate` for corruption

**EC2 Instance Won't Start:**
- Check AWS Console for any limits or issues
- Verify your AWS region has capacity for the instance type