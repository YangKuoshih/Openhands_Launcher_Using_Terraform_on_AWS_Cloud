#!/bin/bash
cd /home/ec2-user/openhands

# Use the recommended approach from OpenHands docs - use the same image for runtime
cat > docker-compose.yml << 'EOF'
services:
  openhands-app:
    image: docker.all-hands.dev/all-hands-ai/openhands:0.59.0
    container_name: openhands-app
    pull_policy: always
    stdin_open: true
    tty: true
    environment:
      - SANDBOX_RUNTIME_CONTAINER_IMAGE=docker.all-hands.dev/all-hands-ai/openhands:0.59.0
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

# Restart containers
docker-compose down
docker-compose up -d

echo "Using same image for both app and runtime - this should work reliably"