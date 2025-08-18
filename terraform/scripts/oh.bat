@echo off
echo Opening OpenHands...
echo.

cd /d "%~dp0\.."
for /f "tokens=*" %%i in ('terraform output -raw openhands_url 2^>nul') do set OPENHANDS_URL=%%i

if "%OPENHANDS_URL%"=="" (
    echo Error: Cannot get OpenHands URL. Make sure infrastructure is deployed.
    pause
    exit /b
)

echo Opening: %OPENHANDS_URL%
start "" "%OPENHANDS_URL%"
echo.
echo Browser should open automatically.
echo If it doesn't, manually open: %OPENHANDS_URL%
echo.
pause