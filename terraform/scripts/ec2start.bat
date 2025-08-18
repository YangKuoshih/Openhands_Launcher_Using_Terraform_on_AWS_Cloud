@echo off
call "%~dp0\status.bat"

cd /d "%~dp0\.."

REM Get instance ID from Terraform output
for /f "tokens=*" %%i in ('terraform output -raw instance_id 2^>nul') do set INSTANCE_ID=%%i

if "%INSTANCE_ID%"=="" (
    echo Error: Cannot get instance ID. Make sure infrastructure is deployed.
    pause
    exit /b
)

echo.
echo Starting EC2 instance %INSTANCE_ID%...
aws ec2 start-instances --instance-ids %INSTANCE_ID%

if %ERRORLEVEL% EQU 0 (
    echo.
    echo Instance start command sent successfully!
    echo It may take 1-2 minutes for the instance to be fully running.
    echo Use 'status' to check current state.
) else (
    echo.
    echo Failed to start instance. Check your AWS credentials and permissions.
)

pause