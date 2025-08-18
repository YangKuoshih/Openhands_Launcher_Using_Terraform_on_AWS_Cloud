# Alternative Setup Options

## Option 1: Enable WSL2 (Recommended)
1. **Run as Administrator**: Right-click `enable-wsl2.bat` → "Run as administrator"
2. **Restart your computer** when prompted
3. After restart, run `start-openhands.bat`

## Option 2: Use Docker without WSL2 (Legacy Mode)
If you can't enable WSL2, you can try switching Docker Desktop to legacy mode:

1. Open Docker Desktop settings
2. Go to General tab
3. Uncheck "Use the WSL 2 based engine"
4. Apply & Restart

**Note**: This may have limitations and is not recommended for production use.

## Option 3: Cloud-based Setup
If local Docker setup is problematic, consider:
- AWS EC2 instance with Docker
- GitHub Codespaces
- Other cloud development environments

## Checking Virtualization
To check if virtualization is enabled in BIOS:
1. Open Task Manager → Performance tab → CPU
2. Look for "Virtualization: Enabled"
3. If disabled, enable it in BIOS settings

## Next Steps After WSL2 Setup
1. Restart computer
2. Run `start-openhands.bat`
3. Access OpenHands at http://localhost:8150
4. Configure LLM settings as described in SETUP-INSTRUCTIONS.md