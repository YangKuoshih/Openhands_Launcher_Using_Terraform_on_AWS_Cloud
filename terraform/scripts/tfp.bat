@echo off
call "%~dp0\status.bat"
echo.
echo Running terraform plan...
echo.

cd /d "%~dp0\.."
terraform plan

pause