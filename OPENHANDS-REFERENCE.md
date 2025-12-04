# OpenHands Official Documentation Reference

## Official Documentation
- **Main Documentation**: https://docs.openhands.dev/overview/introduction
- **GitHub Repository**: https://github.com/All-Hands-AI/OpenHands

## Docker Image Configuration

### Correct Image Locations

**OpenHands App:**
- Registry: `docker.all-hands.dev/all-hands-ai/openhands`
- Example: `docker.all-hands.dev/all-hands-ai/openhands:0.59.0`

**Runtime Container:**
- **RECOMMENDED**: Use the same app image as runtime
- Example: `docker.all-hands.dev/all-hands-ai/openhands:0.59.0`
- **Why**: Separate runtime images (`ghcr.io/all-hands-ai/runtime`) are outdated and incompatible

### Environment Variable

```bash
# CORRECT - Use app image as runtime
SANDBOX_RUNTIME_CONTAINER_IMAGE=docker.all-hands.dev/all-hands-ai/openhands:0.59.0
```

## Common Errors

### Error: "stat /openhands/micromamba/bin/micromamba: no such file or directory"

**Cause**: Using outdated separate runtime image (`ghcr.io/all-hands-ai/runtime:latest` is 15+ months old)

**Solution**: Use the app image as runtime container

**Correct Configuration**:
```yaml
services:
  openhands-app:
    image: docker.all-hands.dev/all-hands-ai/openhands:0.59.0
    environment:
      # Use same image for runtime - this is the fix!
      - SANDBOX_RUNTIME_CONTAINER_IMAGE=docker.all-hands.dev/all-hands-ai/openhands:0.59.0
```

## Version Compatibility

**CRITICAL ISSUE RESOLVED:**
- Separate runtime images (`ghcr.io/all-hands-ai/runtime:*`) are outdated
- Version-specific runtime tags (e.g., `0.59.0`) don't exist in the registry
- **Solution**: Use the app image for both app and runtime containers

**Working Configuration:**
- App: `docker.all-hands.dev/all-hands-ai/openhands:0.59.0`
- Runtime: `docker.all-hands.dev/all-hands-ai/openhands:0.59.0` (same image)

**To verify images exist:**
```bash
docker pull docker.all-hands.dev/all-hands-ai/openhands:0.59.0  # Works
```

## Deployment Best Practices

1. **Pin Versions**: Always use specific version tags, not `latest`
2. **Test Images**: Pull images manually to verify they exist
3. **Match Versions**: Runtime must match app version exactly
4. **Check Logs**: Use Portainer or `docker logs` to troubleshoot
5. **Clean State**: Remove old containers before deploying new versions

## Troubleshooting Commands

```bash
# Check running containers
docker ps -a

# View OpenHands logs
docker logs openhands-app

# View runtime container logs (if created)
docker logs $(docker ps -aq --filter "name=runtime")

# Remove failed containers
docker rm -f $(docker ps -aq --filter "name=runtime")
docker rm -f openhands-app

# Pull fresh images
docker pull docker.all-hands.dev/all-hands-ai/openhands:0.59.0
docker pull ghcr.io/all-hands-ai/runtime:0.59.0

# Restart deployment
cd /home/ec2-user/openhands
docker-compose down
docker-compose up -d
```

## Configuration Files

### docker-compose.yml
Located at: `/home/ec2-user/openhands/docker-compose.yml`

### OpenHands Config
Located at: `/home/ec2-user/openhands/.openhands/config.toml`

### LiteLLM Config
Located at: `/home/ec2-user/openhands/litellm-config.yml`

## Additional Resources

- **Docker Hub**: https://hub.docker.com/r/allhandsai/openhands (deprecated, use docker.all-hands.dev)
- **GitHub Container Registry**: https://github.com/orgs/All-Hands-AI/packages
- **Community Discord**: Check official docs for invite link
- **Issue Tracker**: https://github.com/All-Hands-AI/OpenHands/issues

## Notes

- This deployment uses AWS Bedrock via LiteLLM proxy
- Runtime containers are ephemeral and created per-session
- The app container manages runtime container lifecycle
- Docker socket must be mounted for runtime container creation
