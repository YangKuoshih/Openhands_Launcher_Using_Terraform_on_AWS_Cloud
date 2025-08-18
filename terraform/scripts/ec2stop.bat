@echo off
cd /d "%~dp0\.."

REM Get instance ID from Terraform output
for /f "tokens=*" %%i in ('terraform output -raw instance_id 2^>nul') do set INSTANCE_ID=%%i

if "%INSTANCE_ID%"=="" (
    echo Error: Cannot get instance ID. Make sure infrastructure is deployed.
    exit /b
)

echo Stopping EC2 instance %INSTANCE_ID%...
aws ec2 stop-instances --instance-ids %INSTANCE_ID%

if %ERRORLEVEL% EQU 0 (
    echo Instance stop command sent successfully!
    echo It may take 1-2 minutes for the instance to be fully stopped.
) else (
    echo Failed to stop instance. Check your AWS credentials and permissions.
)