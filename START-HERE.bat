@echo off
title OpenHands AWS Setup

echo.
echo ================================================================
echo                    OpenHands AWS Setup
echo                 AI Coding Assistant on AWS
echo ================================================================
echo.
echo This will automatically:
echo  * Check prerequisites (AWS CLI, Terraform)
echo  * Configure AWS credentials
echo  * Deploy OpenHands infrastructure
echo  * Open OpenHands in your browser
echo.
echo Press any key to start setup...
pause >nul

echo.
echo Starting setup...
cd /d "%~dp0terraform"

REM Check AWS credentials
echo Checking AWS credentials...
aws sts get-caller-identity >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo.
    echo Setting up AWS SSO authentication...
    echo This will open your browser for AWS login.
    echo.
    pause
    
    cd /d "%~dp0terraform\scripts"
    call setup-aws-sso.bat
    if %ERRORLEVEL% NEQ 0 (
        echo.
        echo SSO setup failed. Please set credentials manually:
        echo   export AWS_ACCESS_KEY_ID="your_key"
        echo   export AWS_SECRET_ACCESS_KEY="your_secret"
        echo   export AWS_SESSION_TOKEN="your_token"
        echo.
        pause
        exit /b
    )
    cd /d "%~dp0terraform"
)

echo AWS credentials OK
echo.
echo Initializing Terraform...
terraform init
echo.
echo Checking for existing infrastructure...
terraform plan -detailed-exitcode >nul 2>&1
if %ERRORLEVEL% EQU 2 (
    echo.
    echo Existing infrastructure detected.
    echo Would you like to:
    echo   1. Update existing infrastructure (recommended)
    echo   2. Destroy and recreate all
    echo.
    set /p choice="Enter choice (1 or 2): "
    if "%choice%"=="2" (
        echo.
        echo Destroying existing infrastructure...
        terraform destroy -auto-approve
        echo.
    )
)
echo Starting Terraform deployment (this may take 3-5 minutes)...
terraform apply -auto-approve

echo.
echo ================================================================
echo                      Setup Complete!
echo ================================================================
echo.
echo Daily usage: Run launcher.bat
echo.
cd /d "%~dp0"
pause