@echo off
echo ===============================================
echo OpenHands Redeploy Script
echo ===============================================
echo.
echo This will:
echo 1. Destroy existing infrastructure
echo 2. Apply updated configuration (v0.61.0)
echo.
echo WARNING: This will terminate the current instance!
echo.
set /p confirm="Are you sure? (yes/no): "
if not "%confirm%"=="yes" (
    echo.
    echo Cancelled.
    pause
    exit /b
)

cd /d "%~dp0terraform"

echo.
echo Step 1: Destroying existing infrastructure...
echo ===============================================
terraform destroy -auto-approve

if %ERRORLEVEL% NEQ 0 (
    echo.
    echo Destroy failed. Check the error messages above.
    pause
    exit /b 1
)

echo.
echo Step 2: Applying updated configuration...
echo ===============================================
terraform apply -auto-approve

if %ERRORLEVEL% EQU 0 (
    echo.
    echo ===============================================
    echo Redeployment completed successfully!
    echo ===============================================
    echo.
    echo OpenHands v0.61.0 is now deploying...
    echo Allow 2-3 minutes for containers to start.
    echo.
    echo Run launcher.bat to access OpenHands
) else (
    echo.
    echo Apply failed. Check the error messages above.
)

echo.
pause
