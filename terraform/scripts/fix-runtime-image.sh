#!/bin/bash
cd /home/ec2-user/openhands

echo "Stopping containers..."
docker-compose down

echo "Updating docker-compose.yml with correct runtime image..."
sed -i 's|ghcr.io/all-hands-ai/runtime:0.59.0|ghcr.io/all-hands-ai/runtime:latest|' docker-compose.yml

echo "Verifying change..."
grep SANDBOX_RUNTIME docker-compose.yml

echo "Starting containers..."
docker-compose up -d

echo "Checking container status..."
docker ps

echo ""
echo "Done! Check OpenHands logs with: docker logs openhands-app -f"
