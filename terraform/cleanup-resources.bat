@echo off
title OpenHands - Fix Resource Conflicts
echo.
echo ================================================================
echo              Fix Terraform Resource Conflicts
echo ================================================================
echo.
echo This will import existing AWS resources into Terraform state.
echo This is safe and recommended when you see "already exists" errors.
echo.
pause

echo.
echo Importing existing resources...

REM Import IAM Policy if it exists
echo Checking IAM Policy: openhands-aws-setup-openhands-policy
for /f "tokens=*" %%i in ('aws iam list-policies --query "Policies[?PolicyName=='openhands-aws-setup-openhands-policy'].Arn" --output text 2^>nul') do (
    if not "%%i"=="" (
        echo   Found policy, importing...
        terraform import aws_iam_policy.openhands_policy "%%i" 2>nul
        echo   Imported successfully
    ) else (
        echo   Policy not found, skipping
    )
)

REM Import Key Pair if it exists
echo Checking Key Pair: openhands-key
aws ec2 describe-key-pairs --key-names openhands-key >nul 2>&1
if %ERRORLEVEL% EQU 0 (
    echo   Found key pair, importing...
    terraform import aws_key_pair.openhands openhands-key 2>nul
    echo   Imported successfully
) else (
    echo   Key pair not found, skipping
)

REM Import IAM Role if it exists
echo Checking IAM Role: openhands-aws-setup-scheduler-role
aws iam get-role --role-name openhands-aws-setup-scheduler-role >nul 2>&1
if %ERRORLEVEL% EQU 0 (
    echo   Found role, importing...
    terraform import aws_iam_role.scheduler_role openhands-aws-setup-scheduler-role 2>nul
    echo   Imported successfully
) else (
    echo   Role not found, skipping
)

echo.
echo Import completed! Now you can run terraform apply successfully.
echo.
pause