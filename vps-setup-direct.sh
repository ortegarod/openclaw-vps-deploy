#!/bin/bash
#
# vps-setup-direct.sh - Direct OpenClaw installation (no Docker)
#
# Called by deploy.sh (don't run this manually)
#

set -e

AGENT_NAME="$1"
TELEGRAM_TOKEN="$2"
API_KEY="$3"
MODEL="$4"

echo "========================================"
echo "VPS Setup - Direct OpenClaw Installation"
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
apt-get install -y -qq curl git ufw

# Configure firewall first
echo "→ Configuring firewall..."
ufw --force enable
ufw allow 22/tcp    # SSH
ufw allow 80/tcp    # HTTP (for future webhooks)
ufw allow 443/tcp   # HTTPS
ufw reload

# Install OpenClaw using official installer
echo "→ Installing OpenClaw (this installs Node.js if needed)..."
curl -fsSL https://openclaw.ai/install.sh | bash

# Reload shell environment
export PATH="$HOME/.openclaw/bin:$PATH"
source ~/.bashrc 2>/dev/null || true

# Verify installation
if command -v openclaw &> /dev/null; then
    OPENCLAW_VERSION=$(openclaw --version 2>/dev/null || echo "unknown")
    echo "✓ OpenClaw installed: $OPENCLAW_VERSION"
else
    echo "⚠️  OpenClaw command not found in PATH, but installation may have succeeded"
    echo "Checking /root/.openclaw/bin..."
    if [ -f "/root/.openclaw/bin/openclaw" ]; then
        export PATH="/root/.openclaw/bin:$PATH"
        echo "✓ Found OpenClaw in /root/.openclaw/bin"
    fi
fi

# Create config directory
echo "→ Creating OpenClaw configuration..."
mkdir -p /root/.openclaw/workspace/memory

# Create config.json
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

OpenClaw agent deployed and configured (direct installation).

Agent name: $AGENT_NAME
Model: $MODEL

Ready to assist.
DAILY_EOF

# Find openclaw binary path
OPENCLAW_BIN=$(which openclaw 2>/dev/null || echo "/root/.openclaw/bin/openclaw")

# Create systemd service for auto-restart
echo "→ Creating systemd service..."
cat > /etc/systemd/system/openclaw.service <<SERVICE_EOF
[Unit]
Description=OpenClaw Gateway
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/root
Environment="PATH=/root/.openclaw/bin:/usr/local/bin:/usr/bin:/bin"
ExecStart=$OPENCLAW_BIN gateway start
Restart=always
RestartSec=10
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
SERVICE_EOF

# Enable and start service
systemctl daemon-reload
systemctl enable openclaw
systemctl start openclaw

# Wait for startup
echo "→ Waiting for gateway to start..."
sleep 10

# Check status
if systemctl is-active --quiet openclaw; then
  echo "✓ Gateway is running"
else
  echo "⚠️  Gateway may not be running properly"
  echo "Status:"
  systemctl status openclaw --no-pager
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
echo "  Service: systemctl status openclaw"
echo ""
echo "Useful commands:"
echo "  Check logs: journalctl -u openclaw -f"
echo "  Restart: systemctl restart openclaw"
echo "  Stop: systemctl stop openclaw"
echo ""
