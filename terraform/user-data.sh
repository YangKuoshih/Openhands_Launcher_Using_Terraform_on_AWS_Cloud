#!/bin/bash
yum update -y

# Install Docker
yum install -y docker
systemctl start docker
systemctl enable docker
usermod -a -G docker ec2-user

# Install Docker Compose
curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

# Create OpenHands directory
mkdir -p /home/ec2-user/openhands
cd /home/ec2-user/openhands

# Create docker-compose.yml
cat > docker-compose.yml << 'EOF'
services:
  openhands-app:
    image: docker.all-hands.dev/all-hands-ai/openhands:0.53
    container_name: openhands-app
    pull_policy: always
    stdin_open: true
    tty: true
    environment:
      - SANDBOX_RUNTIME_CONTAINER_IMAGE=docker.all-hands.dev/all-hands-ai/runtime:0.53-nikolaik
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
EOF

# Create litellm-config.yml
cat > litellm-config.yml << 'EOF'
model_list:
  - model_name: Claude3
    litellm_params:
      model: anthropic.claude-3-haiku-20240307-v1:0
  - model_name: NovaPro1
    litellm_params:
      model: bedrock/amazon.nova-pro-v1:0
  - model_name: Claude3.7
    litellm_params:
      model: us.anthropic.claude-3-7-sonnet-20250219-v1:0
  - model_name: Claude4
    litellm_params:
      model: us.anthropic.claude-sonnet-4-20250514-v1:0
  - model_name: ClaudeOpus4.1
    litellm_params:
      model: us.anthropic.claude-opus-4-1-20250805-v1:0

litellm_settings:
  modify_params: True
  drop_params: true
EOF

# Create OpenHands configuration file
mkdir -p /home/ec2-user/openhands/.openhands
cat > /home/ec2-user/openhands/.openhands/config.toml << 'EOF'
[core]
workspace_base = "/workspace"
persist_sandbox = false

[llm]
model = "litellm_proxy/Claude4"
api_key = "openhands-key-2025"
base_url = "http://litellm"
temperature = 0.0
max_iterations = 100

[agent]
name = "CodeActAgent"
memory_enabled = true
EOF

# Set ownership
chown -R ec2-user:ec2-user /home/ec2-user/openhands

# Start OpenHands
cd /home/ec2-user/openhands
docker-compose up -d

# Create startup script for auto-restart
cat > /home/ec2-user/start-openhands.sh << 'EOF'
#!/bin/bash
cd /home/ec2-user/openhands
docker-compose up -d
EOF

chmod +x /home/ec2-user/start-openhands.sh
chown ec2-user:ec2-user /home/ec2-user/start-openhands.sh

# Create systemd service for reliable auto-start
cat > /etc/systemd/system/openhands.service << 'EOF'
[Unit]
Description=OpenHands Docker Compose
Requires=docker.service
After=docker.service

[Service]
Type=oneshot
RemainAfterExit=yes
WorkingDirectory=/home/ec2-user/openhands
ExecStart=/usr/local/bin/docker-compose up -d
ExecStop=/usr/local/bin/docker-compose down
User=ec2-user
Group=ec2-user

[Install]
WantedBy=multi-user.target
EOF

# Enable the service
systemctl enable openhands.service
systemctl start openhands.service

# Also add cron as backup
echo "@reboot sleep 30 && /home/ec2-user/start-openhands.sh" | crontab -u ec2-user -