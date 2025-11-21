@echo off
echo ===============================================
echo OpenHands Launcher
echo ===============================================
echo.

cd /d "%~dp0terraform"

echo Loading infrastructure info...
REM Get infrastructure status
for /f "tokens=*" %%i in ('terraform output -raw instance_id 2^>nul') do set INSTANCE_ID=%%i
for /f "tokens=*" %%i in ('terraform output -raw instance_public_ip 2^>nul') do set PUBLIC_IP=%%i
for /f "tokens=*" %%i in ('terraform output -raw instance_public_dns 2^>nul') do set PUBLIC_DNS=%%i
for /f "tokens=*" %%i in ('terraform output -raw openhands_url 2^>nul') do set OPENHANDS_URL=%%i

if "%INSTANCE_ID%"=="" (
    echo Status: Infrastructure not deployed
    echo Run START-HERE.bat first to deploy OpenHands infrastructure
    echo.
    echo Press any key to exit...
    pause >nul
    exit /b
)

echo Instance ID: %INSTANCE_ID%
echo Public IP: %PUBLIC_IP%
echo Public DNS: %PUBLIC_DNS%
echo.
echo Checking EC2 status...
REM Get instance state
for /f "tokens=*" %%i in ('aws ec2 describe-instances --instance-ids %INSTANCE_ID% --query "Reservations[0].Instances[0].State.Name" --output text 2^>nul') do set STATE=%%i

if "%STATE%"=="running" (
    echo Status: RUNNING
    echo OpenHands URL: %OPENHANDS_URL%
    echo.
    echo OpenHands should be starting up (allow 2-3 minutes)
) else (
    if "%STATE%"=="stopped" (
        echo Status: STOPPED
        echo OpenHands URL: Not available (instance stopped)
    ) else (
        if "%STATE%"=="pending" (
            echo Status: STARTING...
            echo OpenHands URL: Will be available at %OPENHANDS_URL%
        ) else (
            if "%STATE%"=="stopping" (
                echo Status: STOPPING...
                echo OpenHands URL: Not available
            ) else (
                echo Status: %STATE%
                echo OpenHands URL: %OPENHANDS_URL%
            )
        )
    )
)

echo.
echo Schedule: Auto-stop at 10 PM EST, Auto-start at 8 AM EST
echo.

:menu
echo ===============================================
echo Select a command:
echo ===============================================
echo 1. oh        - Open OpenHands in browser
echo 2. ec2       - SSH to EC2 instance
echo 3. portainer - Open Portainer in browser
echo 4. status    - Refresh status
echo 5. ec2start  - Manually start EC2 instance
echo 6. ec2stop   - Manually stop EC2 instance
echo 7. tfp       - Plan infrastructure changes
echo 8. tfa       - Update infrastructure
echo 9. tfd       - Destroy infrastructure
echo 10. cleanup  - Fix resource conflicts
echo 11. Exit
echo.
set /p choice="Enter your choice (1-11): "

if "%choice%"=="1" call "%~dp0terraform\scripts\oh.bat" && goto menu
if "%choice%"=="2" call "%~dp0terraform\scripts\ec2.bat" && goto menu
if "%choice%"=="3" call "%~dp0terraform\scripts\portainer.bat" && goto menu
if "%choice%"=="4" cls && "%~dp0launcher.bat" && exit /b
if "%choice%"=="5" call "%~dp0terraform\scripts\ec2start.bat" && goto menu
if "%choice%"=="6" call "%~dp0terraform\scripts\ec2stop.bat" && goto menu
if "%choice%"=="7" call "%~dp0terraform\scripts\tfp.bat" && goto menu
if "%choice%"=="8" call "%~dp0terraform\scripts\tfa.bat" && goto menu
if "%choice%"=="9" call "%~dp0terraform\scripts\tfd.bat" && goto menu
if "%choice%"=="10" call "%~dp0terraform\terraform-state-cleanup.bat" && goto menu
if "%choice%"=="11" cd /d "%~dp0" && exit /b

echo Invalid choice. Please enter 1-11.
goto menu