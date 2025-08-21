@echo off
title OpenHands - Fix Resource Conflicts
echo.
echo ================================================================
echo              Fix Terraform Resource Conflicts
echo ================================================================
echo.
echo This will import existing AWS resources into Terraform state.
echo This is safe and fixes "already exists" errors.
echo.
pause
echo.
echo Importing existing AWS resources into Terraform state...
echo This allows Terraform to manage existing resources.
echo.

REM Import IAM Policy
echo Checking IAM Policy: openhands-aws-setup-openhands-policy
for /f "tokens=*" %%i in ('aws iam list-policies --query "Policies[?PolicyName=='openhands-aws-setup-openhands-policy'].Arn" --output text 2^>nul') do (
    if not "%%i"=="" (
        echo   Found policy, importing...
        terraform import aws_iam_policy.openhands_policy "%%i"
    ) else (
        echo   Policy not found in AWS
    )
)

REM Import Key Pair
echo Checking Key Pair: openhands-key
aws ec2 describe-key-pairs --key-names openhands-key >nul 2>&1
if %ERRORLEVEL% EQU 0 (
    echo   Found key pair, importing...
    terraform import aws_key_pair.openhands openhands-key
) else (
    echo   Key pair not found in AWS
)

REM Import OpenHands IAM Role
echo Checking IAM Role: openhands-aws-setup-openhands-role
aws iam get-role --role-name openhands-aws-setup-openhands-role >nul 2>&1
if %ERRORLEVEL% EQU 0 (
    echo   Found openhands role, importing...
    terraform import aws_iam_role.openhands_role openhands-aws-setup-openhands-role
) else (
    echo   OpenHands role not found in AWS
)

REM Import Scheduler IAM Role
echo Checking IAM Role: openhands-aws-setup-scheduler-role
aws iam get-role --role-name openhands-aws-setup-scheduler-role >nul 2>&1
if %ERRORLEVEL% EQU 0 (
    echo   Found scheduler role, importing...
    terraform import aws_iam_role.scheduler_role openhands-aws-setup-scheduler-role
) else (
    echo   Scheduler role not found in AWS
)

echo.
echo Import completed! Now you can run terraform apply successfully.
echo.
echo Done!
pause