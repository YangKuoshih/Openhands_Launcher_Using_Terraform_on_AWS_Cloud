@echo off
echo ========================================
echo AWS SSO Helper Setup
echo ========================================
echo.

REM Check if Python is installed
python --version >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo Error: Python is not installed or not in PATH
    echo Please install Python 3.7+ and try again
    pause
    exit /b 1
)

REM Navigate to AWS SSO Helper directory
cd /d "%~dp0aws_sso_helper"

REM Install dependencies
echo Installing AWS SSO Helper dependencies...
pip install -r requirements.txt
if %ERRORLEVEL% NEQ 0 (
    echo Error: Failed to install dependencies
    pause
    exit /b 1
)

echo.
echo Dependencies installed successfully!
echo.

REM Check if config.ini exists
if not exist "config.ini" (
    echo Warning: config.ini not found
    echo Please copy config.ini.example to config.ini and configure your SSO settings
    echo.
    if exist "config.ini.example" (
        echo Would you like to copy the example config? (y/n)
        set /p choice=
        if /i "%choice%"=="y" (
            copy "config.ini.example" "config.ini"
            echo Example config copied. Please edit config.ini with your SSO details.
        )
    )
    echo.
    pause
    exit /b 1
)

echo Running AWS SSO Helper...
echo This will authenticate you with AWS SSO and set up profiles
echo.
python aws_sso_helper.py

if %ERRORLEVEL% EQU 0 (
    echo.
    echo ========================================
    echo AWS SSO Setup Complete!
    echo ========================================
    echo.
    echo You can now run Terraform commands.
    echo Your AWS credentials have been updated.
) else (
    echo.
    echo AWS SSO setup failed. Please check the error messages above.
)

echo.
pause