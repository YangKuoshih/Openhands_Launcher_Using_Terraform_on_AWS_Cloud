#!/bin/bash
echo "=== Checking OpenHands Configuration ==="
echo ""

echo "1. Docker Compose Configuration:"
if [ -f /home/ec2-user/openhands/docker-compose.yml ]; then
    echo "   App Image:"
    grep "image: docker.all-hands.dev" /home/ec2-user/openhands/docker-compose.yml | head -1
    echo "   Runtime Image:"
    grep "SANDBOX_RUNTIME_CONTAINER_IMAGE" /home/ec2-user/openhands/docker-compose.yml
else
    echo "   ❌ docker-compose.yml not found"
fi

echo ""
echo "2. Running Containers:"
docker ps --format "table {{.Names}}\t{{.Image}}\t{{.Status}}"

echo ""
echo "3. OpenHands App Container Details:"
if docker ps -q -f name=openhands-app > /dev/null 2>&1; then
    docker inspect openhands-app --format '   Image: {{.Config.Image}}'
    docker inspect openhands-app --format '   Runtime Env: {{range .Config.Env}}{{println .}}{{end}}' | grep SANDBOX_RUNTIME
else
    echo "   ❌ openhands-app container not running"
fi

echo ""
echo "4. Available Images:"
docker images | grep -E "openhands|runtime" || echo "   No OpenHands images found"

echo ""
echo "5. Runtime Container (if exists):"
RUNTIME_CONTAINER=$(docker ps -aq --filter "name=runtime" | head -1)
if [ -n "$RUNTIME_CONTAINER" ]; then
    docker inspect $RUNTIME_CONTAINER --format '   Image: {{.Config.Image}}'
    docker inspect $RUNTIME_CONTAINER --format '   Status: {{.State.Status}}'
else
    echo "   No runtime container found (this is normal if no task is running)"
fi

echo ""
echo "=== Version Check Complete ==="
