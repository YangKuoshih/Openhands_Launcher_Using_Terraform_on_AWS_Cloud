#!/bin/bash
cd /home/ec2-user/openhands
sed -i 's/"--spider", "-q"/"-q", "-O", "\/dev\/null"/g' docker-compose.yml
docker rm -f ecs-agent 2>/dev/null
docker-compose up -d litellm
sleep 40
docker-compose up -d openhands-app
echo ""
echo "Container status:"
docker ps -a
