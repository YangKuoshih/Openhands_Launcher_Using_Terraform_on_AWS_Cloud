@echo off
echo ===============================================
echo OpenHands Infrastructure Setup
echo ===============================================
echo.

REM Check if we're in the scripts directory
if not exist "..\config.json" (
    echo Error: Please run this from the terraform\scripts directory
    echo Expected location: openhands-setup-and-learn\terraform\scripts\
    echo.
    echo Press any key to exit...
    pause >nul
    exit /b
)
echo Config file found - correct directory
echo.

echo Checking prerequisites...
echo.

echo Step 1: Checking AWS CLI...
aws --version >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo AWS CLI not found. Please install AWS CLI first.
    echo Download from: https://awscli.amazonaws.com/AWSCLIV2.msi
    echo Press any key to exit...
    pause >nul
    exit /b
) else (
    echo AWS CLI found
)
echo.

echo Step 2: Checking Terraform...
terraform version >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo Terraform not found. Please install Terraform first.
    echo Download from: https://www.terraform.io/downloads
    echo Press any key to exit...
    pause >nul
    exit /b
) else (
    echo Terraform found
)
echo.

echo Step 3: Checking AWS credentials...
echo Testing AWS credentials with 'aws sts get-caller-identity'...
aws sts get-caller-identity >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo.
    echo ERROR: AWS credentials are not configured or invalid.
    echo.
    echo Please update your AWS credentials in one of these ways:
    echo 1. Run: aws configure
    echo 2. Update ~/.aws/credentials file manually
    echo 3. Set environment variables: AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY
    echo.
    echo After updating credentials, run this script again.
    echo.
    echo Press any key to exit...
    pause >nul
    exit /b
) else (
    echo AWS credentials working
)
echo.

echo ===============================================
echo All prerequisites ready! Deploying infrastructure...
echo ===============================================
echo.

call "%~dp0tfa.bat"

echo.
echo ===============================================
echo Setup Complete!
echo ===============================================
echo.
echo Next steps:
echo 1. Use launcher.bat for daily operations
echo 2. Run launcher.bat to access OpenHands
echo.
pause