@echo off
call "%~dp0\status.bat"

cd /d "%~dp0\.."

REM Get OpenHands URL from Terraform output
for /f "tokens=*" %%i in ('terraform output -raw openhands_url 2^>nul') do set OPENHANDS_URL=%%i

if "%OPENHANDS_URL%"=="" (
    echo Error: Cannot get OpenHands URL. Make sure infrastructure is deployed.
    pause
    exit /b
)

REM Check if instance is running
for /f "tokens=*" %%i in ('terraform output -raw instance_id 2^>nul') do set INSTANCE_ID=%%i
for /f "tokens=*" %%i in ('aws ec2 describe-instances --instance-ids %INSTANCE_ID% --query "Reservations[0].Instances[0].State.Name" --output text 2^>nul') do set STATE=%%i

if not "%STATE%"=="running" (
    echo Error: EC2 instance is not running (State: %STATE%)
    echo Use 'ec2start' to start the instance first.
    pause
    exit /b
)

echo.
echo Opening OpenHands in your default browser...
echo URL: %OPENHANDS_URL%
echo.
echo Note: OpenHands may take 2-3 minutes to be fully available after instance start.
echo.

REM Try multiple ways to open browser
echo Attempting to open browser...
start "" "%OPENHANDS_URL%"
if %ERRORLEVEL% NEQ 0 (
    echo Browser failed to open automatically.
    echo Please manually open: %OPENHANDS_URL%
    echo.
    echo Copy this URL to your browser:
    echo %OPENHANDS_URL%
)
echo.
echo Press any key to continue...
pause >nul