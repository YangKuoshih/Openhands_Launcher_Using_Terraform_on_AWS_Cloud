@echo off
echo Checking Portainer status on EC2...
cd /d "%~dp0\.."

for /f "tokens=*" %%i in ('terraform output -raw instance_public_ip 2^>nul') do set PUBLIC_IP=%%i

if "%PUBLIC_IP%"=="" (
    echo Error: Could not get instance IP
    pause
    exit /b 1
)

echo Connecting to %PUBLIC_IP%...
echo.
ssh -i keys/openhands-key.pem -o StrictHostKeyChecking=no ec2-user@%PUBLIC_IP% "cd /home/ec2-user/openhands && docker-compose ps && echo. && echo Checking if Portainer is in docker-compose.yml: && grep -A 5 portainer docker-compose.yml"

echo.
pause
