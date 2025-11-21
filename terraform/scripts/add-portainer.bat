@echo off
echo Adding Portainer to running EC2 instance...
cd /d "%~dp0\.."

for /f "tokens=*" %%i in ('terraform output -raw instance_public_ip 2^>nul') do set PUBLIC_IP=%%i

if "%PUBLIC_IP%"=="" (
    echo Error: Could not get instance IP
    pause
    exit /b 1
)

echo Connecting to %PUBLIC_IP%...
echo Updating docker-compose.yml with Portainer...
echo.

ssh -i keys/openhands-key.pem -o StrictHostKeyChecking=no ec2-user@%PUBLIC_IP% "cd /home/ec2-user/openhands && cp docker-compose.yml docker-compose.yml.backup && cat >> docker-compose.yml << 'PORTAINER_EOF'

  portainer:
    image: portainer/portainer-ce:latest
    container_name: portainer
    pull_policy: always
    restart: unless-stopped
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
      - portainer_data:/data
    ports:
      - \"9000:9000\"

volumes:
  portainer_data:
PORTAINER_EOF
docker-compose pull && docker-compose up -d"

if %ERRORLEVEL% EQU 0 (
    echo.
    echo Portainer added successfully!
    echo Access it at: http://%PUBLIC_IP%:9000
) else (
    echo.
    echo Failed to add Portainer. Try manual SSH method.
)

echo.
pause
