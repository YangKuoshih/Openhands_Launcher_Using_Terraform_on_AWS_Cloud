@echo off
echo Checking Portainer status...
cd /d "%~dp0\.."

REM Get instance info
for /f "tokens=*" %%i in ('terraform output -raw instance_public_ip 2^>nul') do set PUBLIC_IP=%%i
for /f "tokens=*" %%i in ('terraform output -raw openhands_url 2^>nul') do set OPENHANDS_URL=%%i

if "%PUBLIC_IP%"=="" (
    echo Error: Could not get instance IP from terraform output
    pause
    exit /b 1
)

REM Check if Portainer is running
echo Checking if Portainer container is running...
ssh -i keys/openhands-key.pem -o StrictHostKeyChecking=no -o ConnectTimeout=5 ec2-user@%PUBLIC_IP% "docker ps --filter name=portainer --format '{{.Names}}'" > temp_portainer_check.txt 2>nul

findstr /C:"portainer" temp_portainer_check.txt >nul 2>&1
if %ERRORLEVEL% EQU 0 (
    echo Portainer is running!
    del temp_portainer_check.txt
) else (
    echo Portainer is not running. Starting Portainer...
    del temp_portainer_check.txt
    ssh -i keys/openhands-key.pem -o StrictHostKeyChecking=no ec2-user@%PUBLIC_IP% "cd /home/ec2-user/openhands && docker-compose up -d portainer 2>/dev/null || docker run -d -p 9000:9000 --name portainer --restart=unless-stopped -v /var/run/docker.sock:/var/run/docker.sock -v portainer_data:/data portainer/portainer-ce:latest"
    if %ERRORLEVEL% EQU 0 (
        echo Portainer started successfully!
        timeout /t 3 >nul
    ) else (
        echo Failed to start Portainer. Please check EC2 instance.
        pause
        exit /b 1
    )
)

REM Replace port 8150 with 9000 for Portainer
set PORTAINER_URL=%OPENHANDS_URL:8150=9000%

echo Opening Portainer in browser...
echo Portainer URL: %PORTAINER_URL%
start %PORTAINER_URL%
