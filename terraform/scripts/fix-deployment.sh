#!/bin/bash

# OpenHands Deployment Fix Script
# Attempts to fix common deployment issues

echo "========================================="
echo "OpenHands Deployment Fix Script"
echo "========================================="

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}1. Stopping existing containers${NC}"
cd /home/ec2-user/openhands
docker-compose down 2>/dev/null || true

echo -e "\n${BLUE}2. Cleaning up Docker resources${NC}"
docker system prune -f
docker volume prune -f

echo -e "\n${BLUE}3. Checking Docker daemon${NC}"
if ! systemctl is-active docker > /dev/null 2>&1; then
    echo -e "${YELLOW}Starting Docker service...${NC}"
    systemctl start docker
    sleep 5
fi

echo -e "\n${BLUE}4. Verifying user permissions${NC}"
usermod -a -G docker ec2-user
chown -R ec2-user:ec2-user /home/ec2-user/openhands

echo -e "\n${BLUE}5. Pulling latest images${NC}"
cd /home/ec2-user/openhands

# Get latest OpenHands version
echo "Detecting latest OpenHands version..."
LATEST_VERSION=$(docker run --rm gcr.io/go-containerregistry/crane:debug ls docker.all-hands.dev/all-hands-ai/openhands | grep -E '^[0-9]+\.[0-9]+\.[0-9]+$' | sort -V | tail -1)
echo "Using OpenHands version: $LATEST_VERSION"

# Pull images explicitly
docker pull docker.all-hands.dev/all-hands-ai/openhands:${LATEST_VERSION}
docker pull docker.all-hands.dev/all-hands-ai/runtime:${LATEST_VERSION}
docker pull ghcr.io/berriai/litellm:main-latest
docker pull portainer/portainer-ce:latest

echo -e "\n${BLUE}6. Recreating docker-compose.yml with latest version${NC}"
cat > docker-compose.yml << EOF
services:
  openhands-app:
    image: docker.all-hands.dev/all-hands-ai/openhands:${LATEST_VERSION}
    container_name: openhands-app
    pull_policy: always
    stdin_open: true
    tty: true
    environment:
      - SANDBOX_RUNTIME_CONTAINER_IMAGE=docker.all-hands.dev/all-hands-ai/runtime:${LATEST_VERSION}
      - LOG_ALL_EVENTS=true
      - LLM_MODEL=litellm_proxy/Claude4
      - LLM_BASE_URL=http://litellm
      - LLM_API_KEY=openhands-key-2025
      - OPENHANDS_LLM_MODEL=litellm_proxy/Claude4
      - OPENHANDS_LLM_BASE_URL=http://litellm
      - OPENHANDS_LLM_API_KEY=openhands-key-2025
    volumes:
      - ./.openhands:/.openhands
      - /var/run/docker.sock:/var/run/docker.sock
    ports:
      - "8150:3000"
    extra_hosts:
      - "host.docker.internal:host-gateway"
    restart: unless-stopped
    depends_on:
      - litellm

  litellm:
    image: ghcr.io/berriai/litellm:main-latest
    container_name: litellm
    volumes:
      - ./litellm-config.yml:/app/config.yaml
    restart: unless-stopped
    environment:
      - LITELLM_API_KEY=openhands-key-2025
      - AWS_REGION=us-east-1
      - PORT=80
    command: --config /app/config.yaml --detailed_debug
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost/health"]
      interval: 30s
      timeout: 10s
      retries: 3

  portainer:
    image: portainer/portainer-ce:latest
    container_name: portainer
    pull_policy: always
    restart: unless-stopped
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
      - portainer_data:/data
    ports:
      - "9000:9000"

volumes:
  portainer_data:
EOF

echo -e "\n${BLUE}7. Verifying configuration files${NC}"
if [ ! -f "litellm-config.yml" ]; then
    echo -e "${YELLOW}Creating litellm-config.yml...${NC}"
    cat > litellm-config.yml << 'EOF'
model_list:
  - model_name: Claude3
    litellm_params:
      model: anthropic.claude-3-haiku-20240307-v1:0
  - model_name: NovaPro1
    litellm_params:
      model: bedrock/amazon.nova-pro-v1:0
  - model_name: Claude3.7
    litellm_params:
      model: us.anthropic.claude-3-7-sonnet-20250219-v1:0
  - model_name: Claude4
    litellm_params:
      model: us.anthropic.claude-sonnet-4-20250514-v1:0
  - model_name: ClaudeOpus4.1
    litellm_params:
      model: us.anthropic.claude-opus-4-1-20250805-v1:0

litellm_settings:
  modify_params: True
  drop_params: true
EOF
fi

if [ ! -d ".openhands" ]; then
    echo -e "${YELLOW}Creating OpenHands config directory...${NC}"
    mkdir -p .openhands
    cat > .openhands/config.toml << 'EOF'
[core]
workspace_base = "/workspace"
persist_sandbox = false

[llm]
model = "litellm_proxy/Claude4"
api_key = "openhands-key-2025"
base_url = "http://litellm"
temperature = 0.0
max_iterations = 100

[agent]
name = "CodeActAgent"
memory_enabled = true
EOF
fi

echo -e "\n${BLUE}8. Setting correct permissions${NC}"
chown -R ec2-user:ec2-user /home/ec2-user/openhands

echo -e "\n${BLUE}9. Starting services${NC}"
sudo -u ec2-user docker-compose up -d

echo -e "\n${BLUE}10. Waiting for services to start${NC}"
sleep 30

echo -e "\n${BLUE}11. Checking service status${NC}"
docker-compose ps

echo -e "\n${BLUE}12. Testing connectivity${NC}"
echo "Testing OpenHands..."
timeout 30 bash -c 'until curl -s http://localhost:8150 > /dev/null; do sleep 2; done' && echo -e "${GREEN}✓ OpenHands is responding${NC}" || echo -e "${RED}✗ OpenHands not responding${NC}"

echo "Testing Portainer..."
timeout 30 bash -c 'until curl -s http://localhost:9000 > /dev/null; do sleep 2; done' && echo -e "${GREEN}✓ Portainer is responding${NC}" || echo -e "${RED}✗ Portainer not responding${NC}"

echo "Testing LiteLLM..."
timeout 30 bash -c 'until docker exec litellm curl -s http://localhost/health > /dev/null 2>&1; do sleep 2; done' && echo -e "${GREEN}✓ LiteLLM is responding${NC}" || echo -e "${RED}✗ LiteLLM not responding${NC}"

echo -e "\n${BLUE}13. Updating systemd service${NC}"
systemctl daemon-reload
systemctl restart openhands.service
systemctl enable openhands.service

echo -e "\n========================================="
echo -e "${GREEN}Fix script completed!${NC}"
echo "========================================="

# Get public IP
PUBLIC_IP=$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)

echo -e "\n${BLUE}Access URLs:${NC}"
echo -e "OpenHands: ${GREEN}http://${PUBLIC_IP}:8150${NC}"
echo -e "Portainer: ${GREEN}http://${PUBLIC_IP}:9000${NC}"

echo -e "\n${YELLOW}Next steps:${NC}"
echo "1. Run the test script: ./test-deployment.sh"
echo "2. Check container logs if issues persist: docker logs <container-name>"
echo "3. Verify AWS Bedrock model access in AWS Console"