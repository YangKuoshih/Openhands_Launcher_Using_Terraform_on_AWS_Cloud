@echo off
cd /d "%~dp0\.."

REM Get public DNS from Terraform output
for /f "tokens=*" %%i in ('terraform output -raw instance_public_dns 2^>nul') do set PUBLIC_DNS=%%i

if "%PUBLIC_DNS%"=="" (
    echo Error: Cannot get instance DNS. Make sure infrastructure is deployed.
    pause
    exit /b
)

echo.
echo Connecting to EC2 instance via SSH...
echo DNS: %PUBLIC_DNS%
echo.

REM Check if private key exists
if not exist "keys\openhands-key.pem" (
    echo Error: SSH private key 'openhands-key.pem' not found in keys directory.
    echo Make sure you've deployed the infrastructure with 'tfa' first.
    pause
    exit /b
)

echo SSH key found: keys\openhands-key.pem
echo.
echo Testing network connectivity...
echo Pinging host: %PUBLIC_DNS%
ping -n 2 %PUBLIC_DNS%
echo.
echo Testing port 22 connectivity...
telnet %PUBLIC_DNS% 22
echo.
echo If telnet worked, attempting SSH connection...
echo Command: ssh -i "keys\openhands-key.pem" -o StrictHostKeyChecking=no -o ConnectTimeout=10 ec2-user@%PUBLIC_DNS%
echo.
echo If this hangs, press Ctrl+C to cancel
echo.

echo Starting Docker containers first...
ssh -i "keys\openhands-key.pem" -o StrictHostKeyChecking=no -o ConnectTimeout=10 ec2-user@%PUBLIC_DNS% "cd /home/ec2-user/openhands && docker-compose up -d"
echo.
echo Docker containers started. Connecting to SSH...
echo.
ssh -i "keys\openhands-key.pem" -o StrictHostKeyChecking=no -o ConnectTimeout=10 ec2-user@%PUBLIC_DNS%

echo.
echo SSH session ended. Press any key to continue...
pause >nul