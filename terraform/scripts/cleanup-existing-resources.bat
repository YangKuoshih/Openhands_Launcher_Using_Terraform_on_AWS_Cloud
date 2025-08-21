@echo off
title OpenHands - Cleanup Existing Resources
echo.
echo ================================================================
echo                 OpenHands Resource Cleanup
echo ================================================================
echo.
echo This script will help resolve conflicts with existing AWS resources.
echo.
echo Choose an option:
echo   1. Import existing resources into Terraform (recommended)
echo   2. Delete existing resources from AWS (destructive)
echo   3. Cancel
echo.
set /p choice="Enter choice (1-3): "

if "%choice%"=="1" goto import_resources
if "%choice%"=="2" goto delete_resources
if "%choice%"=="3" exit /b
echo Invalid choice. Exiting.
exit /b

:import_resources
echo.
echo Importing existing resources into Terraform state...
echo.

REM Import IAM Policy
echo Importing IAM Policy: openhands-aws-setup-openhands-policy
for /f "tokens=*" %%i in ('aws iam list-policies --query "Policies[?PolicyName=='openhands-aws-setup-openhands-policy'].Arn" --output text 2^>nul') do (
    if not "%%i"=="" (
        terraform import aws_iam_policy.openhands_policy "%%i"
    )
)

REM Import Key Pair
echo Importing Key Pair: openhands-key
terraform import aws_key_pair.openhands openhands-key 2>nul

REM Import IAM Role
echo Importing IAM Role: openhands-aws-setup-scheduler-role
terraform import aws_iam_role.scheduler_role openhands-aws-setup-scheduler-role 2>nul

echo.
echo Import completed. Now running terraform plan to check status...
terraform plan
goto end

:delete_resources
echo.
echo WARNING: This will permanently delete existing AWS resources!
echo This action cannot be undone.
echo.
set /p confirm="Type 'DELETE' to confirm: "
if not "%confirm%"=="DELETE" (
    echo Cancelled.
    exit /b
)

echo.
echo Deleting existing resources...

REM Delete IAM Policy
echo Deleting IAM Policy: openhands-aws-setup-openhands-policy
for /f "tokens=*" %%i in ('aws iam list-policies --query "Policies[?PolicyName=='openhands-aws-setup-openhands-policy'].Arn" --output text 2^>nul') do (
    if not "%%i"=="" (
        aws iam delete-policy --policy-arn "%%i" 2>nul
        echo   - Policy deleted
    )
)

REM Delete Key Pair
echo Deleting Key Pair: openhands-key
aws ec2 delete-key-pair --key-name openhands-key 2>nul
echo   - Key pair deleted

REM Delete IAM Role (detach policies first)
echo Deleting IAM Role: openhands-aws-setup-scheduler-role
for /f "tokens=*" %%i in ('aws iam list-attached-role-policies --role-name openhands-aws-setup-scheduler-role --query "AttachedPolicies[].PolicyArn" --output text 2^>nul') do (
    aws iam detach-role-policy --role-name openhands-aws-setup-scheduler-role --policy-arn "%%i" 2>nul
)
for /f "tokens=*" %%i in ('aws iam list-role-policies --role-name openhands-aws-setup-scheduler-role --query "PolicyNames[]" --output text 2^>nul') do (
    aws iam delete-role-policy --role-name openhands-aws-setup-scheduler-role --policy-name "%%i" 2>nul
)
aws iam delete-role --role-name openhands-aws-setup-scheduler-role 2>nul
echo   - Role deleted

echo.
echo Resources deleted. Now you can run terraform apply.

:end
echo.
echo Done!
pause