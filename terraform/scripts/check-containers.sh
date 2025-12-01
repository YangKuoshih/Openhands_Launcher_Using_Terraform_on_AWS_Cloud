#!/bin/bash

echo "=== Docker Container Status Check ==="
echo "Date: $(date)"
echo

# Check if Docker is running
echo "1. Docker Service Status:"
systemctl is-active docker && echo "✓ Docker is running" || echo "✗ Docker is not running"
echo

# Check running containers
echo "2. Running Containers:"
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}\t{{.Image}}"
echo

# Check all containers (including stopped)
echo "3. All Containers:"
docker ps -a --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}\t{{.Image}}"
echo

# Check specific OpenHands containers
echo "4. OpenHands Container Details:"
for container in openhands-app litellm portainer; do
    if docker ps -q -f name=$container > /dev/null; then
        echo "✓ $container is running"
        docker inspect $container --format "  Image: {{.Config.Image}}"
        docker inspect $container --format "  Status: {{.State.Status}}"
        docker inspect $container --format "  Health: {{.State.Health.Status}}"
    else
        echo "✗ $container is not running"
    fi
done
echo

# Check ports
echo "5. Port Status:"
netstat -tuln | grep -E ":(8150|9000|80)" || echo "No OpenHands ports listening"
echo

# Check recent logs
echo "6. Recent Container Logs (last 5 lines each):"
for container in openhands-app litellm portainer; do
    if docker ps -q -f name=$container > /dev/null; then
        echo "--- $container logs ---"
        docker logs $container --tail 5 2>/dev/null || echo "No logs available"
        echo
    fi
done

# Check Docker Compose status
echo "7. Docker Compose Status:"
if [ -f "/home/ec2-user/openhands/docker-compose.yml" ]; then
    cd /home/ec2-user/openhands
    docker-compose ps 2>/dev/null || echo "Docker Compose not available or no services defined"
else
    echo "docker-compose.yml not found"
fi
echo

# Check systemd service
echo "8. OpenHands Systemd Service:"
systemctl is-active openhands.service && echo "✓ OpenHands service is active" || echo "✗ OpenHands service is not active"
systemctl is-enabled openhands.service && echo "✓ OpenHands service is enabled" || echo "✗ OpenHands service is not enabled"
echo

# Quick connectivity test
echo "9. Quick Connectivity Test:"
curl -s --connect-timeout 5 http://localhost:8150 > /dev/null && echo "✓ OpenHands (8150) responds" || echo "✗ OpenHands (8150) not responding"
curl -s --connect-timeout 5 http://localhost:9000 > /dev/null && echo "✓ Portainer (9000) responds" || echo "✗ Portainer (9000) not responding"

echo
echo "=== End of Status Check ==="