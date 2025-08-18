@echo off
echo Deploying OpenHands Infrastructure...
echo.

cd /d "%~dp0\.."

echo Note: SSH keys will be generated automatically by Terraform

echo Running terraform init...
terraform init

echo.
echo Running terraform apply...
terraform apply -auto-approve

if %ERRORLEVEL% EQU 0 (
    echo.
    echo ===============================================
    echo Deployment completed successfully!
    echo ===============================================
) else (
    echo.
    echo Deployment failed. Check the error messages above.
)