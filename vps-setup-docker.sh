#!/bin/bash
#
# vps-setup-docker.sh - Install OpenClaw on VPS (Official Docker method)
#
# Based on: https://docs.openclaw.ai/install/hetzner
# Called by deploy.sh (don't run this manually)
#

set -e

AGENT_NAME="$1"
TELEGRAM_TOKEN="$2"
API_KEY="$3"
MODEL="$4"

echo "========================================"
echo "OpenClaw VPS Setup (Docker)"
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
apt-get install -y -qq git curl ca-certificates ufw

# Install Docker (official method)
echo "→ Installing Docker..."
if ! command -v docker &> /dev/null; then
    curl -fsSL https://get.docker.com | sh
fi

# Verify
docker --version
docker compose version

# Configure firewall
echo "→ Configuring firewall..."
ufw --force enable
ufw allow 22/tcp
ufw allow 80/tcp
ufw allow 443/tcp
ufw reload

# Clone OpenClaw repository
echo "→ Cloning OpenClaw repository..."
if [ -d "/root/openclaw" ]; then
    echo "Repository exists, pulling latest..."
    cd /root/openclaw
    git pull
else
    cd /root
    git clone https://github.com/openclaw/openclaw.git
    cd openclaw
fi

# Create persistent directories
echo "→ Creating persistent directories..."
mkdir -p /root/.openclaw
mkdir -p /root/.openclaw/workspace

# Set ownership (container runs as uid 1000)
chown -R 1000:1000 /root/.openclaw
chown -R 1000:1000 /root/.openclaw/workspace

# Generate secrets
GATEWAY_TOKEN=$(openssl rand -hex 32)
KEYRING_PASSWORD=$(openssl rand -hex 32)

# Create .env file
echo "→ Creating environment configuration..."
cd /root/openclaw
cat > .env <<ENV_EOF
OPENCLAW_IMAGE=openclaw:latest
OPENCLAW_GATEWAY_TOKEN=$GATEWAY_TOKEN
OPENCLAW_GATEWAY_BIND=lan
OPENCLAW_GATEWAY_PORT=18789

OPENCLAW_CONFIG_DIR=/root/.openclaw
OPENCLAW_WORKSPACE_DIR=/root/.openclaw/workspace

GOG_KEYRING_PASSWORD=$KEYRING_PASSWORD
XDG_CONFIG_HOME=/home/node/.openclaw
ENV_EOF

# Create docker-compose.yml
echo "→ Creating Docker Compose configuration..."
cat > docker-compose.yml <<'COMPOSE_EOF'
services:
  openclaw-gateway:
    image: ${OPENCLAW_IMAGE}
    build: .
    restart: unless-stopped
    env_file:
      - .env
    environment:
      - HOME=/home/node
      - NODE_ENV=production
      - TERM=xterm-256color
      - OPENCLAW_GATEWAY_BIND=${OPENCLAW_GATEWAY_BIND}
      - OPENCLAW_GATEWAY_PORT=${OPENCLAW_GATEWAY_PORT}
      - OPENCLAW_GATEWAY_TOKEN=${OPENCLAW_GATEWAY_TOKEN}
      - GOG_KEYRING_PASSWORD=${GOG_KEYRING_PASSWORD}
      - XDG_CONFIG_HOME=${XDG_CONFIG_HOME}
      - PATH=/home/linuxbrew/.linuxbrew/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
    volumes:
      - ${OPENCLAW_CONFIG_DIR}:/home/node/.openclaw
      - ${OPENCLAW_WORKSPACE_DIR}:/home/node/.openclaw/workspace
    ports:
      - "127.0.0.1:${OPENCLAW_GATEWAY_PORT}:18789"
    command:
      [
        "node",
        "dist/index.js",
        "gateway",
        "--bind",
        "${OPENCLAW_GATEWAY_BIND}",
        "--port",
        "${OPENCLAW_GATEWAY_PORT}",
      ]
COMPOSE_EOF

# Create config.json
echo "→ Creating OpenClaw configuration..."
cat > /root/.openclaw/config.json <<CONFIG_EOF
{
  "gateway": {
    "mode": "production",
    "bind": "lan",
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

# Fix ownership
chown 1000:1000 /root/.openclaw/config.json

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
mkdir -p /root/.openclaw/workspace/memory
TODAY=$(date +%Y-%m-%d)
cat > "/root/.openclaw/workspace/memory/$TODAY.md" <<DAILY_EOF
# $TODAY

## Setup

OpenClaw agent deployed via Docker (official method).

Agent name: $AGENT_NAME
Model: $MODEL

Ready to assist.
DAILY_EOF

# Fix ownership
chown -R 1000:1000 /root/.openclaw/workspace

# Build and start
echo "→ Building OpenClaw image..."
cd /root/openclaw
docker compose build

echo "→ Starting OpenClaw gateway..."
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
echo "✅ Setup Complete!"
echo "========================================"
echo ""
echo "OpenClaw repository: /root/openclaw"
echo "Configuration: /root/.openclaw/config.json"
echo "Workspace: /root/.openclaw/workspace"
echo ""
echo "Gateway token (save this): $GATEWAY_TOKEN"
echo ""
echo "Useful commands:"
echo "  Check logs: cd /root/openclaw && docker compose logs -f openclaw-gateway"
echo "  Restart: cd /root/openclaw && docker compose restart openclaw-gateway"
echo "  Stop: cd /root/openclaw && docker compose down"
echo ""
