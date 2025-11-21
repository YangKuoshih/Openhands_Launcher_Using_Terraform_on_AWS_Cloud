@echo off
echo Updating OpenHands to latest version...
cd /d "%~dp0\.."

for /f "tokens=*" %%i in ('terraform output -raw instance_public_ip 2^>nul') do set PUBLIC_IP=%%i

if "%PUBLIC_IP%"=="" (
    echo Error: Could not get instance IP
    pause
    exit /b 1
)

echo Connecting to %PUBLIC_IP%...
echo Updating docker-compose.yml and pulling latest images...
echo.

ssh -i keys/openhands-key.pem -o StrictHostKeyChecking=no ec2-user@%PUBLIC_IP% "cd /home/ec2-user/openhands && cp docker-compose.yml docker-compose.yml.backup && cat docker-compose.yml | sed 's/openhands:0.53/openhands:latest/g' | sed 's/runtime:0.53-nikolaik/runtime:latest/g' > docker-compose.yml.new && mv docker-compose.yml.new docker-compose.yml && docker-compose pull && docker-compose up -d"

if %ERRORLEVEL% EQU 0 (
    echo.
    echo Update successful! Checking new version...
    ssh -i keys/openhands-key.pem -o StrictHostKeyChecking=no ec2-user@%PUBLIC_IP% "docker inspect openhands-app --format='Running: {{.Config.Image}}'"
) else (
    echo.
    echo Update failed. Restoring backup...
    ssh -i keys/openhands-key.pem -o StrictHostKeyChecking=no ec2-user@%PUBLIC_IP% "cd /home/ec2-user/openhands && mv docker-compose.yml.backup docker-compose.yml"
)

echo.
pause
