#!/bin/bash
cd /home/ec2-user/openhands
docker rm -f $(docker ps -a | grep openhands-runtime | awk '{print $1}') 2>/dev/null
sed -i '/SANDBOX_RUNTIME_CONTAINER_IMAGE/a\      - SANDBOX_USER_ID=1000' docker-compose.yml
docker-compose up -d openhands-app
echo "Fix applied. Try starting a new conversation in OpenHands."
