@echo off
echo Enabling WSL2 and Virtual Machine Platform...
echo This script must be run as Administrator!
echo.

REM Enable Virtual Machine Platform
echo Enabling Virtual Machine Platform...
dism.exe /online /enable-feature /featurename:VirtualMachinePlatform /all /norestart

REM Enable WSL feature
echo Enabling Windows Subsystem for Linux...
dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart

REM Install WSL2
echo Installing WSL2...
wsl.exe --install --no-distribution

echo.
echo Setup complete! You need to RESTART your computer for changes to take effect.
echo After restart, run start-openhands.bat to launch OpenHands.
echo.
pause