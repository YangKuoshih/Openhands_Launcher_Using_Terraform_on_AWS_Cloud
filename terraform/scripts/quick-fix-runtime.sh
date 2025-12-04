#!/bin/bash

# Quick Fix Script for Existing OpenHands Deployments
# This script fixes the runtime container error without redeploying infrastructure
# Run this on your EC2 instance to fix the "/openhands/micromamba/bin/micromamba" error

echo "========================================="
echo "OpenHands Runtime Quick Fix"
echo "========================================="
echo ""
echo "This will fix the runtime container error by:"
echo "1. Using the app image as runtime container"
echo "2. Adding explicit Docker network"
echo "3. Adding proper health checks and dependencies"
echo ""

cd /home/ec2-user/openhands || exit 1

# Stop existing containers
echo "Stopping existing containers..."
docker-compose down

# Backup existing configuration
echo "Backing up existing docker-compose.yml..."
cp docker-compose.yml docker-compose.yml.backup.$(date +%Y%m%d_%H%M%S)

# Set version
OPENHANDS_VERSION="0.59.0"

# Create new docker-compose.yml with fixed configuration
echo "Creating fixed docker-compose.yml..."
cat > docker-compose.yml <<EOF
networks:
  openhands-network:
    driver: bridge

services:
  litellm:
    image: ghcr.io/berriai/litellm:main-latest
    container_name: litellm
    networks:
      - openhands-network
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
      start_period: 40s

  openhands-app:
    image: docker.all-hands.dev/all-hands-ai/openhands:${OPENHANDS_VERSION}
    container_name: openhands-app
    pull_policy: always
    stdin_open: true
    tty: true
    networks:
      - openhands-network
    environment:
      # CRITICAL FIX: Use app image as runtime to avoid outdated runtime image issues
      - SANDBOX_RUNTIME_CONTAINER_IMAGE=docker.all-hands.dev/all-hands-ai/openhands:${OPENHANDS_VERSION}
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
      litellm:
        condition: service_healthy

  portainer:
    image: portainer/portainer-ce:latest
    container_name: portainer
    pull_policy: always
    networks:
      - openhands-network
    restart: unless-stopped
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
      - portainer_data:/data
    ports:
      - "9000:9000"

volumes:
  portainer_data:
EOF

# Pull the correct image
echo "Pulling OpenHands image..."
docker pull docker.all-hands.dev/all-hands-ai/openhands:${OPENHANDS_VERSION}

# Start containers with new configuration
echo "Starting containers with fixed configuration..."
docker-compose up -d

# Wait for services to start
echo "Waiting for services to start..."
sleep 30

# Check status
echo ""
echo "========================================="
echo "Container Status:"
echo "========================================="
docker-compose ps

echo ""
echo "========================================="
echo "Fix Complete!"
echo "========================================="
echo ""
echo "The runtime error should now be fixed."
echo "Try creating a new conversation in OpenHands."
echo ""
echo "If you still have issues, check logs with:"
echo "  docker logs openhands-app"
echo "  docker logs litellm"
echo ""
