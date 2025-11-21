@echo off
echo Deploying OpenHands Infrastructure...
echo.

cd /d "%~dp0\.."

echo Note: SSH keys will be generated automatically by Terraform

echo Running terraform init...
terraform init

echo.
echo Running terraform apply...
terraform apply -auto-approve

if %ERRORLEVEL% EQU 0 (
    echo.
    echo ===============================================
    echo Deployment completed successfully!
    echo ===============================================
    echo.
    echo Updating OpenHands containers to latest version...
    
    REM Get instance ID
    for /f "tokens=*" %%i in ('terraform output -raw instance_id 2^>nul') do set INSTANCE_ID=%%i
    
    if not "%INSTANCE_ID%"=="" (
        REM Check if instance is running
        for /f "tokens=*" %%i in ('aws ec2 describe-instances --instance-ids %INSTANCE_ID% --query "Reservations[0].Instances[0].State.Name" --output text 2^>nul') do set STATE=%%i
        
        if "%STATE%"=="running" (
            echo Instance is running, updating OpenHands containers...
            aws ssm send-command --instance-ids %INSTANCE_ID% --document-name "AWS-RunShellScript" --parameters "commands=['cd /home/ec2-user/openhands && docker-compose pull && docker-compose up -d']" --output text >nul 2>&1
            if %ERRORLEVEL% EQU 0 (
                echo OpenHands containers updated successfully!
            ) else (
                echo Failed to update containers. You can manually update by:
                echo 1. SSH to EC2 instance
                echo 2. Run: cd /home/ec2-user/openhands ^&^& docker-compose pull ^&^& docker-compose up -d
            )
        ) else (
            echo Instance is not running (%STATE%). Containers will use latest version on next start.
        )
    )
) else (
    echo.
    echo Deployment failed. Check the error messages above.
)