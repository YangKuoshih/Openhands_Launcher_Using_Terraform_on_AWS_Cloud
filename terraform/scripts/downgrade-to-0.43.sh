#!/bin/bash
cd /home/ec2-user/openhands
docker-compose down

# Backup current config
cp docker-compose.yml docker-compose.yml.backup.0.59.0

# Create new config for 0.43.0
# Note: For 0.43.0, we'll try using the default runtime image behavior first
# or explicitly set it if needed. Older versions often defaulted to a specific runtime.
# Let's try setting it to the app image first, as that's often a safer bet if the app image has the tools.
# BUT, if 0.59.0 didn't have it, 0.43.0 might not either.
# Let's try the standard configuration for older versions which often used 'ghcr.io/all-hands-ai/runtime:latest'
# effectively by default or explicit config.

cat > docker-compose.yml <<'EOF'
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

  openhands-app:
    image: docker.all-hands.dev/all-hands-ai/openhands:0.43.0
    container_name: openhands-app
    pull_policy: always
    stdin_open: true
    tty: true
    networks:
      - openhands-network
    environment:
      - SANDBOX_RUNTIME_CONTAINER_IMAGE=docker.all-hands.dev/all-hands-ai/runtime:0.43.0
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
        condition: service_started

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

# Note: I am trying to use a version-matched runtime image: docker.all-hands.dev/all-hands-ai/runtime:0.43.0
# If that doesn't exist, we might need to fallback.

echo "Pulling images..."
docker pull docker.all-hands.dev/all-hands-ai/openhands:0.43.0
docker pull docker.all-hands.dev/all-hands-ai/runtime:0.43.0 || echo "Runtime 0.43.0 not found, will try to run anyway (might fallback or fail)"

docker-compose up -d
echo "Downgrade complete. Checking logs..."
sleep 5
docker-compose ps
