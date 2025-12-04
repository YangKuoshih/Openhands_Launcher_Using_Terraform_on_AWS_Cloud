@echo off
setlocal enabledelayedexpansion

echo Checking OpenHands versions on EC2...
echo.

REM Get EC2 instance IP
for /f "tokens=*" %%i in ('terraform output -raw instance_public_ip 2^>nul') do set INSTANCE_IP=%%i

if "%INSTANCE_IP%"=="" (
    echo Error: Could not get EC2 instance IP
    echo Make sure Terraform has been applied successfully
    pause
    exit /b 1
)

echo Connecting to EC2 instance: %INSTANCE_IP%
echo.

REM Check if SSH key exists
if not exist "%~dp0..\keys\openhands-key.pem" (
    echo Error: SSH key not found at %~dp0..\keys\openhands-key.pem
    pause
    exit /b 1
)

REM Upload and run the check script
scp -i "%~dp0..\keys\openhands-key.pem" -o StrictHostKeyChecking=no "%~dp0check-versions.sh" ec2-user@%INSTANCE_IP%:/tmp/check-versions.sh
ssh -i "%~dp0..\keys\openhands-key.pem" -o StrictHostKeyChecking=no ec2-user@%INSTANCE_IP% "chmod +x /tmp/check-versions.sh && /tmp/check-versions.sh"

echo.
pause
