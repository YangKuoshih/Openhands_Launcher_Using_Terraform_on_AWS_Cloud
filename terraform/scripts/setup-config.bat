@echo off
echo ===============================================
echo Configuration Setup
echo ===============================================
echo.

cd /d "%~dp0\.."

REM Check if config.json exists
if exist "config.json" (
    echo config.json already exists. Skipping...
) else (
    if exist "config.json.example" (
        echo Creating config.json from example...
        copy "config.json.example" "config.json"
        echo config.json created successfully!
    ) else (
        echo ERROR: config.json.example not found!
    )
)

echo.

REM Check if config.ini exists
if exist "scripts\aws_sso_helper\config.ini" (
    echo config.ini already exists. Skipping...
) else (
    if exist "scripts\aws_sso_helper\config.ini.example" (
        echo Creating config.ini from example...
        copy "scripts\aws_sso_helper\config.ini.example" "scripts\aws_sso_helper\config.ini"
        echo config.ini created successfully!
        echo.
        echo IMPORTANT: Edit scripts\aws_sso_helper\config.ini with your AWS SSO URL
    ) else (
        echo config.ini.example already exists, using it...
    )
)

echo.
echo Configuration setup complete!
echo.
pause
