#!/bin/bash
#
# vps-setup.sh - Runs on the VPS to install OpenClaw
#
# Called by deploy.sh (don't run this manually)
#

set -e

AGENT_NAME="$1"
TELEGRAM_TOKEN="$2"
API_KEY="$3"
MODEL="$4"

echo "========================================"
echo "VPS Setup - OpenClaw Installation"
echo "========================================"
echo "Hostname: $(hostname)"
echo "Agent: $AGENT_NAME"
echo "========================================"
echo ""

# Update system
echo "→ Updating system packages..."
export DEBIAN_FRONTEND=noninteractive
apt-get update -qq
apt-get upgrade -y -qq
apt-get install -y -qq curl git docker.io docker-compose ufw

# Enable Docker
echo "→ Enabling Docker..."
systemctl enable docker >/dev/null 2>&1
systemctl start docker

# Configure firewall
echo "→ Configuring firewall..."
ufw --force enable
ufw allow 22/tcp    # SSH
ufw allow 80/tcp    # HTTP (for future webhooks)
ufw allow 443/tcp   # HTTPS
ufw reload

# Create OpenClaw directory
echo "→ Setting up OpenClaw..."
mkdir -p /opt/openclaw
cd /opt/openclaw

# Create docker-compose.yml
cat > docker-compose.yml <<'COMPOSE_EOF'
version: '3.8'

services:
  openclaw-gateway:
    image: ghcr.io/openclaw/openclaw:latest
    container_name: openclaw-gateway
    restart: unless-stopped
    ports:
      - "18789:18789"
    volumes:
      - /root/.openclaw:/home/node/.openclaw
      - /root/.openclaw/workspace:/home/node/.openclaw/workspace
    environment:
      - NODE_ENV=production
    command: ["node", "dist/index.js", "gateway", "start", "--allow-unconfigured"]

  openclaw-cli:
    image: ghcr.io/openclaw/openclaw:latest
    container_name: openclaw-cli
    profiles: ["cli"]
    volumes:
      - /root/.openclaw:/home/node/.openclaw
      - /root/.openclaw/workspace:/home/node/.openclaw/workspace
    entrypoint: ["node", "dist/index.js"]
COMPOSE_EOF

echo "→ Pulling OpenClaw Docker image..."
docker compose pull openclaw-gateway

# Create config directory
mkdir -p /root/.openclaw/workspace/memory

# Create config.json
echo "→ Creating OpenClaw configuration..."
cat > /root/.openclaw/config.json <<CONFIG_EOF
{
  "gateway": {
    "mode": "production",
    "bind": "0.0.0.0",
    "port": 18789
  },
  "providers": {
    "anthropic": {
      "apiKey": "$API_KEY"
    }
  },
  "channels": {
    "telegram": {
      "enabled": true,
      "token": "$TELEGRAM_TOKEN"
    }
  },
  "agents": {
    "defaults": {
      "model": {
        "primary": "$MODEL"
      },
      "sandbox": {
        "mode": "off"
      }
    }
  }
}
CONFIG_EOF

# Create workspace files
echo "→ Creating workspace structure..."

cat > /root/.openclaw/workspace/IDENTITY.md <<'IDENTITY_EOF'
# IDENTITY.md

I am an AI agent powered by OpenClaw and Claude.

- **Name:** [Your agent name]
- **Purpose:** [What you're here to do]
- **Capabilities:** File management, web research, task automation, analysis

---

## My Role

I assist with:
- Answering questions and providing information
- Research and analysis
- Document creation and editing
- Task management and reminders
- Process automation

---

*Edit this file to customize your agent's identity*
IDENTITY_EOF

cat > /root/.openclaw/workspace/SOUL.md <<'SOUL_EOF'
# SOUL.md

*This file defines your agent's personality and working style.*

## How I Work

- **Helpful and resourceful** — I find answers and solve problems
- **Clear communicator** — I explain things simply
- **Proactive** — I suggest improvements and automations
- **Trustworthy** — I handle information with care

## Boundaries

- Ask before taking sensitive actions
- Verify important information
- Respect privacy and confidentiality

---

*Customize this to match your preferred tone and style*
SOUL_EOF

cat > /root/.openclaw/workspace/USER.md <<'USER_EOF'
# USER.md

Information about my user(s).

- **Primary user:** [Name]
- **Timezone:** [Timezone]
- **Preferences:** [Communication style, working hours, etc.]

## Context

[Add relevant context about your work, projects, preferences]

---

*Update this with information to help your agent serve you better*
USER_EOF

cat > /root/.openclaw/workspace/TOOLS.md <<'TOOLS_EOF'
# TOOLS.md

Installed skills and tools will be documented here.

## Available Skills

[Will be populated as you add skills]

---

*Track your agent's capabilities here*
TOOLS_EOF

cat > /root/.openclaw/workspace/MEMORY.md <<'MEMORY_EOF'
# MEMORY.md

Long-term memory and important context.

## Important Information

[Facts, preferences, decisions to remember]

---

*Your agent's persistent memory lives here*
MEMORY_EOF

# Create today's memory file
TODAY=$(date +%Y-%m-%d)
cat > "/root/.openclaw/workspace/memory/$TODAY.md" <<DAILY_EOF
# $TODAY

## Setup

OpenClaw agent deployed and configured.

Agent name: $AGENT_NAME
Model: $MODEL

Ready to assist.
DAILY_EOF

# Start the gateway
echo "→ Starting OpenClaw gateway..."
cd /opt/openclaw
docker compose up -d openclaw-gateway

# Wait for startup
echo "→ Waiting for gateway to start..."
sleep 10

# Check status
if docker compose ps openclaw-gateway | grep -q "Up"; then
  echo "✓ Gateway is running"
else
  echo "⚠️  Gateway may not be running properly"
  echo "Logs:"
  docker compose logs openclaw-gateway
fi

echo ""
echo "========================================"
echo "✅ VPS Setup Complete!"
echo "========================================"
echo ""
echo "OpenClaw is running on port 18789"
echo "Telegram bot should be active"
echo ""
echo "Configuration:"
echo "  Config: /root/.openclaw/config.json"
echo "  Workspace: /root/.openclaw/workspace"
echo "  Compose: /opt/openclaw/docker-compose.yml"
echo ""
echo "Check logs:"
echo "  docker compose -f /opt/openclaw/docker-compose.yml logs -f"
echo ""
