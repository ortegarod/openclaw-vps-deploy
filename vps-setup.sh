#!/bin/bash
#
# vps-setup.sh - Install OpenClaw on VPS (Official method)
#
# Based on: https://docs.openclaw.ai/install
# Uses official installer + onboarding wizard (non-interactive mode)
#

set -e

AGENT_NAME="$1"
TELEGRAM_TOKEN="$2"
API_KEY="$3"
MODEL="$4"

echo "========================================"
echo "OpenClaw VPS Setup"
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

# Configure firewall
echo "→ Configuring firewall..."
ufw --force enable
ufw allow 22/tcp
ufw allow 80/tcp
ufw allow 443/tcp
ufw allow 18789/tcp
ufw reload

# Install OpenClaw (official installer)
echo "→ Installing OpenClaw..."
curl -fsSL https://openclaw.ai/install.sh | bash

# Reload PATH
export PATH="/root/.openclaw/bin:$PATH"
source ~/.bashrc 2>/dev/null || true

# Verify installation
if ! command -v openclaw &> /dev/null; then
    if [ -f "/root/.openclaw/bin/openclaw" ]; then
        export PATH="/root/.openclaw/bin:$PATH"
    else
        echo "❌ OpenClaw installation failed"
        exit 1
    fi
fi

echo "✓ OpenClaw installed"

# Run onboarding wizard in non-interactive mode
echo "→ Running OpenClaw onboarding..."
openclaw onboard --non-interactive \
  --mode local \
  --auth-choice apiKey \
  --anthropic-api-key "$API_KEY" \
  --gateway-port 18789 \
  --gateway-bind lan \
  --install-daemon \
  --daemon-runtime node \
  --skip-skills

echo "✓ Onboarding complete"

# Add Telegram channel configuration
echo "→ Configuring Telegram channel..."
openclaw gateway config.patch --raw '{
  "channels": {
    "telegram": {
      "enabled": true,
      "botToken": "'"$TELEGRAM_TOKEN"'",
      "dmPolicy": "pairing"
    }
  }
}' --note "Add Telegram channel"

echo "✓ Telegram configured"

# Gateway should auto-start via daemon (installed with --install-daemon)
echo "→ Waiting for gateway to start..."
sleep 10

# Check status
echo "→ Checking gateway status..."
if openclaw gateway status > /dev/null 2>&1; then
    echo "✓ Gateway is running"
else
    echo "⚠️  Gateway may not be running, starting manually..."
    openclaw gateway start
    sleep 5
fi

# Run doctor check
echo "→ Running diagnostics..."
openclaw doctor || true

echo ""
echo "========================================"
echo "✅ Setup Complete!"
echo "========================================"
echo ""
echo "Configuration: /root/.openclaw/openclaw.json"
echo "Workspace: /root/.openclaw/workspace"
echo ""
echo "Useful commands:"
echo "  Check status: openclaw status"
echo "  View logs: openclaw logs --follow"
echo "  Restart: openclaw gateway restart"
echo "  Diagnostics: openclaw doctor"
echo ""
