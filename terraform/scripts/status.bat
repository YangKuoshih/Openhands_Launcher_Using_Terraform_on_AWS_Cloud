@echo off
setlocal enabledelayedexpansion

echo.
echo ===============================================
echo === OpenHands AWS Infrastructure Status ===
echo ===============================================

cd /d "%~dp0\.."

REM Get instance information from Terraform output
for /f "tokens=*" %%i in ('terraform output -raw instance_id 2^>nul') do set INSTANCE_ID=%%i
for /f "tokens=*" %%i in ('terraform output -raw instance_public_ip 2^>nul') do set PUBLIC_IP=%%i
for /f "tokens=*" %%i in ('terraform output -raw instance_public_dns 2^>nul') do set PUBLIC_DNS=%%i
for /f "tokens=*" %%i in ('terraform output -raw openhands_url 2^>nul') do set OPENHANDS_URL=%%i

if "%INSTANCE_ID%"=="" (
    echo Status: Infrastructure not deployed
    echo Run 'tfa' to deploy OpenHands infrastructure
    goto :shortcuts
)

echo Instance ID: %INSTANCE_ID%
echo Public IP: %PUBLIC_IP%
echo Public DNS: %PUBLIC_DNS%

REM Get instance state from AWS
for /f "tokens=*" %%i in ('aws ec2 describe-instances --instance-ids %INSTANCE_ID% --query "Reservations[0].Instances[0].State.Name" --output text 2^>nul') do set STATE=%%i

if "%STATE%"=="running" (
    echo Status: [92mRUNNING[0m
    echo OpenHands URL: %OPENHANDS_URL%
    echo.
    echo OpenHands should be available in 2-3 minutes after instance start
) else if "%STATE%"=="stopped" (
    echo Status: [91mSTOPPED[0m
    echo OpenHands URL: Not available (instance stopped)
) else if "%STATE%"=="pending" (
    echo Status: [93mSTARTING...[0m
    echo OpenHands URL: Will be available at %OPENHANDS_URL%
) else if "%STATE%"=="stopping" (
    echo Status: [93mSTOPPING...[0m
    echo OpenHands URL: Not available
) else (
    echo Status: %STATE%
)

echo.
echo Schedule: Auto-stop at 10 PM EST, Auto-start at 8 AM EST

:shortcuts
echo.
echo Available Commands:
echo   tfa       - Deploy/Update infrastructure
echo   tfd       - Destroy infrastructure
echo   tfp       - Plan infrastructure changes
echo   ec2       - SSH to EC2 instance
echo   oh        - Open OpenHands in browser
echo   status    - Show this status info
echo   ec2start  - Manually start EC2 instance
echo   ec2stop   - Manually stop EC2 instance
echo ===============================================
echo.