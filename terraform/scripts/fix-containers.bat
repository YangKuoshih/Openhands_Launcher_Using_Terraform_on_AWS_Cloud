@echo off
echo ===============================================
echo Fixing Container Issues
echo ===============================================
echo.
echo This will:
echo 1. Update docker-compose.yml with fixed healthcheck
echo 2. Remove ecs-agent container
echo 3. Restart litellm and openhands-app containers
echo.

cd /d "%~dp0\.."

REM Get instance info
for /f "tokens=*" %%i in ('terraform output -raw instance_public_ip 2^>nul') do set PUBLIC_IP=%%i

if "%PUBLIC_IP%"=="" (
    echo Error: Could not get instance IP from Terraform
    pause
    exit /b 1
)

echo Connecting to EC2 instance at %PUBLIC_IP%...
echo.

REM Create the fix script on EC2
ssh -i keys/openhands-key.pem -o StrictHostKeyChecking=no ec2-user@%PUBLIC_IP% "bash -s" << 'ENDSSH'
cd /home/ec2-user/openhands

echo "Step 1: Backing up current docker-compose.yml..."
cp docker-compose.yml docker-compose.yml.backup

echo "Step 2: Updating healthcheck in docker-compose.yml..."
sed -i 's/"CMD", "curl", "-f"/"CMD", "wget", "-q", "-O", "\/dev\/null"/g' docker-compose.yml
sed -i 's/"--spider", "-q"/"-q", "-O", "\/dev\/null"/g' docker-compose.yml

echo "Step 3: Removing ecs-agent container..."
docker rm -f ecs-agent 2>/dev/null || echo "ecs-agent already removed"

echo "Step 4: Restarting litellm container..."
docker-compose up -d litellm

echo "Step 5: Waiting for litellm to become healthy (30 seconds)..."
sleep 30

echo "Step 6: Starting openhands-app container..."
docker-compose up -d openhands-app

echo ""
echo "Checking container status..."
docker ps -a

echo ""
echo "Fix completed!"
ENDSSH

if %ERRORLEVEL% EQU 0 (
    echo.
    echo ===============================================
    echo Fix completed successfully!
    echo ===============================================
    echo.
    echo Wait 1-2 minutes for OpenHands to fully start
    echo Then use launcher.bat option 1 to open OpenHands
) else (
    echo.
    echo Fix failed. Check error messages above.
)

echo.
pause
