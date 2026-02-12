#!/bin/bash
#
# vps-setup.sh - Install OpenClaw on VPS (Official method)
#
# Based on: https://docs.openclaw.ai/install
# Uses official installer + onboarding wizard (non-interactive mode)
#

set -e

DEPLOYMENT_MODE="$1"
CLEAN_INSTALL="$2"
AGENT_NAME="$3"
TELEGRAM_TOKEN="$4"
TELEGRAM_USER_ID="$5"
AUTH_METHOD="$6"
AUTH_VALUE="$7"
MODEL="$8"

echo "========================================"
echo "OpenClaw VPS Setup"
echo "========================================"
echo "Hostname: $(hostname)"
echo "Mode: $DEPLOYMENT_MODE"
if [ "$DEPLOYMENT_MODE" = "managed" ]; then
  echo "Agent: $AGENT_NAME"
  if [ "$CLEAN_INSTALL" = "true" ]; then
    echo "Clean install: Yes (will wipe workspace)"
  fi
fi
echo "========================================"
echo ""

# Update system
echo "→ Updating system packages..."
export DEBIAN_FRONTEND=noninteractive
sudo apt-get update -qq
sudo apt-get upgrade -y -qq
sudo apt-get install -y -qq curl git ufw

# Configure firewall
echo "→ Configuring firewall..."
sudo ufw --force enable
sudo ufw allow 22/tcp
sudo ufw allow 18789/tcp
sudo ufw reload

# Install OpenClaw (official installer)
echo "→ Installing OpenClaw..."
curl -fsSL https://openclaw.ai/install.sh | bash -s -- --no-onboard

# Reload PATH (installer may have updated it)
export PATH="$HOME/.npm-global/bin:$HOME/.openclaw/bin:$PATH"
source ~/.bashrc 2>/dev/null || true
source ~/.profile 2>/dev/null || true

# Verify installation
if ! command -v openclaw &> /dev/null; then
    if [ -f "$HOME/.openclaw/bin/openclaw" ]; then
        export PATH="$HOME/.openclaw/bin:$PATH"
    else
        echo "❌ OpenClaw installation failed"
        exit 1
    fi
fi

echo "✓ OpenClaw installed"

if [ "$DEPLOYMENT_MODE" = "managed" ]; then
  # Clean workspace if requested
  if [ "$CLEAN_INSTALL" = "true" ]; then
    echo "→ Wiping existing workspace..."
    rm -rf "$HOME/.openclaw/workspace"
    rm -rf "$HOME/.openclaw/agents"
    rm -rf "$HOME/.openclaw/credentials"
    echo "✓ Workspace cleaned"
  fi

  # Run onboarding wizard in non-interactive mode
  echo "→ Running OpenClaw onboarding..."
  if [ "$AUTH_METHOD" = "apiKey" ]; then
    openclaw onboard --non-interactive \
      --accept-risk \
      --mode local \
      --auth-choice apiKey \
      --anthropic-api-key "$AUTH_VALUE" \
      --gateway-port 18789 \
      --gateway-bind lan \
      --install-daemon \
      --daemon-runtime node \
      --skip-skills
  elif [ "$AUTH_METHOD" = "token" ]; then
    openclaw onboard --non-interactive \
      --accept-risk \
      --mode local \
      --auth-choice token \
      --token "$AUTH_VALUE" \
      --token-provider anthropic \
      --gateway-port 18789 \
      --gateway-bind lan \
      --install-daemon \
      --daemon-runtime node \
      --skip-skills
  else
    echo "❌ Invalid auth method: $AUTH_METHOD"
    exit 1
  fi

  echo "✓ Onboarding complete"

  # Stop gateway before configuring (avoid pairing issues)
  echo "→ Stopping gateway for configuration..."
  openclaw gateway stop 2>/dev/null || true
  sleep 2

  # Add Telegram channel configuration (edit JSON directly to avoid pairing issues)
  echo "→ Configuring Telegram channel..."
  CONFIG_FILE="$HOME/.openclaw/openclaw.json"
  
  # Use jq if available, otherwise use node
  if command -v jq &> /dev/null; then
    jq --arg token "$TELEGRAM_TOKEN" --argjson userid "$TELEGRAM_USER_ID" \
      '.channels.telegram = {enabled: true, botToken: $token, dmPolicy: "allowlist", allowFrom: [$userid]}' \
      "$CONFIG_FILE" > "$CONFIG_FILE.tmp" && mv "$CONFIG_FILE.tmp" "$CONFIG_FILE"
  else
    node -e "
      const fs = require('fs');
      const config = JSON.parse(fs.readFileSync('$CONFIG_FILE', 'utf8'));
      config.channels = config.channels || {};
      config.channels.telegram = {
        enabled: true,
        botToken: '$TELEGRAM_TOKEN',
        dmPolicy: 'allowlist',
        allowFrom: [$TELEGRAM_USER_ID]
      };
      fs.writeFileSync('$CONFIG_FILE', JSON.stringify(config, null, 2));
    "
  fi

  echo "✓ Telegram configured (pre-authorized user: $TELEGRAM_USER_ID)"

  # Restart gateway to apply Telegram config
  echo "→ Restarting gateway..."
  openclaw gateway restart
  sleep 5

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
else
  # Self-service mode - just basic installation
  echo "✓ Self-service installation complete"
  echo ""
  echo "Customer must complete setup by running:"
  echo "  ssh $USER@$(hostname -I | awk '{print $1}')"
  echo "  openclaw onboard"
fi

echo ""
echo "========================================"
echo "✅ Setup Complete!"
echo "========================================"
echo ""

if [ "$DEPLOYMENT_MODE" = "managed" ]; then
  echo "Mode: MANAGED (fully configured)"
  echo "Configuration: $HOME/.openclaw/openclaw.json"
  echo "Workspace: $HOME/.openclaw/workspace"
  echo ""
  echo "Bot is ready! Customer can message on Telegram now."
  echo ""
  echo "Useful commands:"
  echo "  Check status: openclaw status"
  echo "  View logs: openclaw logs --follow"
  echo "  Restart: openclaw gateway restart"
  echo "  Diagnostics: openclaw doctor"
else
  echo "Mode: SELF-SERVICE (installation only)"
  echo ""
  echo "Customer must complete setup:"
  echo "  1. SSH into the VPS"
  echo "  2. Run: openclaw onboard"
  echo "  3. Follow the interactive wizard"
  echo ""
  echo "Commands after onboarding:"
  echo "  Check status: openclaw status"
  echo "  View logs: openclaw logs --follow"
fi
echo ""
