# OpenHands Setup Instructions

## Prerequisites
- WSL2 and Virtual Machine Platform enabled (see enable-wsl2.bat)
- Docker Desktop must be running
- AWS credentials configured (for Bedrock access)
- Virtualization enabled in BIOS

## First-Time Setup
1. **Enable WSL2**: Right-click `enable-wsl2.bat` → "Run as administrator"
2. **Restart your computer** when prompted
3. **Start Docker Desktop** after restart

## Quick Start
1. Make sure Docker Desktop is running
2. Double-click `start-openhands.bat` to start OpenHands
3. Wait for containers to start (may take a few minutes on first run)
4. Open your browser and go to: http://localhost:8150

## Configuration in OpenHands Web App
1. Click the gear icon (⚙️) at bottom left
2. Go to LLM tab:
   - Custom Model: `litellm_proxy/Claude4`
   - Base URL: `http://litellm`
   - API Key: `openhands-key-2024`
3. Click Save

## GitHub Integration (Optional)
1. Create a GitHub Personal Access Token:
   - Go to GitHub.com → Settings → Developer settings
   - Personal access tokens → Tokens (classic)
   - Generate new token with `repo` scope
2. In OpenHands web app:
   - Click gear icon → Integrations tab
   - Enter your GitHub token
   - Click Save Changes

## Stopping OpenHands
- Double-click `stop-openhands.bat`
- Or run: `docker-compose down`

## Troubleshooting
- If containers fail to start, ensure Docker Desktop is running
- Check AWS credentials are configured for Bedrock access
- View logs: `docker-compose logs`