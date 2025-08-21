@echo off
echo Destroying OpenHands Infrastructure...
echo.

cd /d "%~dp0\.."

echo Destroying all infrastructure...
terraform destroy -auto-approve

if %ERRORLEVEL% EQU 0 (
    echo.
    echo ===============================================
    echo Infrastructure destroyed successfully!
    echo ===============================================
) else (
    echo.
    echo Destruction failed. Check the error messages above.
)