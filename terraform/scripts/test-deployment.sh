#!/bin/bash

# OpenHands Deployment Test Script
# Tests if OpenHands and Portainer are properly installed and running

echo "========================================="
echo "OpenHands Deployment Test"
echo "========================================="

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Test results
TESTS_PASSED=0
TESTS_FAILED=0

test_result() {
    if [ $1 -eq 0 ]; then
        echo -e "${GREEN}✓ PASS${NC}: $2"
        ((TESTS_PASSED++))
    else
        echo -e "${RED}✗ FAIL${NC}: $2"
        ((TESTS_FAILED++))
    fi
}

echo -e "${BLUE}1. Testing Docker Installation${NC}"
docker --version > /dev/null 2>&1
test_result $? "Docker is installed"

systemctl is-active docker > /dev/null 2>&1
test_result $? "Docker service is running"

echo -e "\n${BLUE}2. Testing Docker Compose Installation${NC}"
docker-compose --version > /dev/null 2>&1
test_result $? "Docker Compose is installed"

echo -e "\n${BLUE}3. Testing OpenHands Directory Structure${NC}"
[ -d "/home/ec2-user/openhands" ]
test_result $? "OpenHands directory exists"

[ -f "/home/ec2-user/openhands/docker-compose.yml" ]
test_result $? "docker-compose.yml exists"

[ -f "/home/ec2-user/openhands/litellm-config.yml" ]
test_result $? "litellm-config.yml exists"

[ -d "/home/ec2-user/openhands/.openhands" ]
test_result $? "OpenHands config directory exists"

echo -e "\n${BLUE}4. Testing Docker Compose Configuration${NC}"
cd /home/ec2-user/openhands
docker-compose config > /dev/null 2>&1
test_result $? "docker-compose.yml is valid"

echo -e "\n${BLUE}5. Testing Container Status${NC}"
OPENHANDS_RUNNING=$(docker ps --filter "name=openhands-app" --format "{{.Names}}" | grep -c "openhands-app")
[ $OPENHANDS_RUNNING -eq 1 ]
test_result $? "OpenHands container is running"

LITELLM_RUNNING=$(docker ps --filter "name=litellm" --format "{{.Names}}" | grep -c "litellm")
[ $LITELLM_RUNNING -eq 1 ]
test_result $? "LiteLLM container is running"

PORTAINER_RUNNING=$(docker ps --filter "name=portainer" --format "{{.Names}}" | grep -c "portainer")
[ $PORTAINER_RUNNING -eq 1 ]
test_result $? "Portainer container is running"

echo -e "\n${BLUE}6. Testing Port Accessibility${NC}"
netstat -tuln | grep ":8150" > /dev/null 2>&1
test_result $? "OpenHands port 8150 is listening"

netstat -tuln | grep ":9000" > /dev/null 2>&1
test_result $? "Portainer port 9000 is listening"

echo -e "\n${BLUE}7. Testing Service Health${NC}"
# Test OpenHands health (with timeout)
timeout 10 curl -s http://localhost:8150 > /dev/null 2>&1
test_result $? "OpenHands web interface responds"

# Test Portainer health (with timeout)
timeout 10 curl -s http://localhost:9000 > /dev/null 2>&1
test_result $? "Portainer web interface responds"

# Test LiteLLM health
timeout 10 curl -s http://localhost/health > /dev/null 2>&1
LITELLM_HEALTH=$?
if [ $LITELLM_HEALTH -ne 0 ]; then
    # Try alternative health check
    docker exec litellm curl -s http://localhost/health > /dev/null 2>&1
    LITELLM_HEALTH=$?
fi
test_result $LITELLM_HEALTH "LiteLLM service responds to health check"

echo -e "\n${BLUE}8. Testing Systemd Service${NC}"
systemctl is-enabled openhands.service > /dev/null 2>&1
test_result $? "OpenHands systemd service is enabled"

systemctl is-active openhands.service > /dev/null 2>&1
test_result $? "OpenHands systemd service is active"

echo -e "\n${BLUE}9. Detailed Container Information${NC}"
echo -e "${YELLOW}Container Status:${NC}"
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

echo -e "\n${YELLOW}Container Resource Usage:${NC}"
docker stats --no-stream --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.MemPerc}}"

echo -e "\n${BLUE}10. Recent Container Logs${NC}"
echo -e "${YELLOW}OpenHands App Logs (last 10 lines):${NC}"
docker logs openhands-app --tail 10 2>/dev/null || echo "No logs available"

echo -e "\n${YELLOW}LiteLLM Logs (last 10 lines):${NC}"
docker logs litellm --tail 10 2>/dev/null || echo "No logs available"

echo -e "\n${YELLOW}Portainer Logs (last 10 lines):${NC}"
docker logs portainer --tail 10 2>/dev/null || echo "No logs available"

echo -e "\n${BLUE}11. Network Connectivity Test${NC}"
# Test internal container communication
docker exec openhands-app curl -s http://litellm/health > /dev/null 2>&1
test_result $? "OpenHands can reach LiteLLM internally"

echo -e "\n${BLUE}12. File Permissions Check${NC}"
[ -r "/home/ec2-user/openhands/docker-compose.yml" ]
test_result $? "docker-compose.yml is readable"

[ -r "/home/ec2-user/openhands/litellm-config.yml" ]
test_result $? "litellm-config.yml is readable"

echo -e "\n========================================="
echo -e "${BLUE}Test Summary${NC}"
echo "========================================="
echo -e "Tests Passed: ${GREEN}$TESTS_PASSED${NC}"
echo -e "Tests Failed: ${RED}$TESTS_FAILED${NC}"

if [ $TESTS_FAILED -eq 0 ]; then
    echo -e "\n${GREEN}🎉 All tests passed! OpenHands deployment is healthy.${NC}"
    echo -e "${GREEN}Access OpenHands at: http://$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4):8150${NC}"
    echo -e "${GREEN}Access Portainer at: http://$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4):9000${NC}"
    exit 0
else
    echo -e "\n${RED}❌ Some tests failed. Deployment needs attention.${NC}"
    
    echo -e "\n${YELLOW}Troubleshooting Steps:${NC}"
    echo "1. Check container logs: docker logs <container-name>"
    echo "2. Restart services: cd /home/ec2-user/openhands && docker-compose restart"
    echo "3. Check disk space: df -h"
    echo "4. Check memory usage: free -h"
    echo "5. Verify AWS credentials and Bedrock access"
    
    exit 1
fi