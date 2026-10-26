#!/bin/bash
#
# vps-setup.sh - Install and configure OpenClaw on the VPS
#
# Run by deploy.sh; you don't run this yourself. Uses the official installer
# and OpenClaw's own CLI for every step: https://docs.openclaw.ai/install
#

set -e

ENV_FILE="$1"
if [ -z "$ENV_FILE" ] || [ ! -f "$ENV_FILE" ]; then
  echo "❌ Missing credentials file. Run this through deploy.sh."
  exit 1
fi
# shellcheck disable=SC1090
source "$ENV_FILE"
rm -f "$ENV_FILE"

echo "========================================"
echo "OpenClaw VPS Setup"
echo "========================================"
echo "Hostname: $(hostname)"
echo "========================================"
echo ""

# Update system
echo "→ Updating system packages..."
# sudo drops exported variables, so pass them inline. Keeps apt from stopping
# on config-file or restart-services questions, and waits for Ubuntu's own
# first-boot updates to finish instead of failing on the package lock.
APT=(sudo DEBIAN_FRONTEND=noninteractive NEEDRESTART_MODE=a apt-get -y -qq
  -o DPkg::Lock::Timeout=600
  -o Dpkg::Options::=--force-confdef -o Dpkg::Options::=--force-confold)
"${APT[@]}" update
"${APT[@]}" upgrade
"${APT[@]}" install curl git ufw

# Lock down the VPS: close all inbound ports except SSH
echo "→ Configuring firewall (SSH only)..."
sudo ufw allow OpenSSH > /dev/null
sudo ufw --force enable > /dev/null
echo "✓ Firewall on: only SSH is open"

# SSH: key logins only. deploy.sh only gets here over key login, so your key
# already works. The 00- prefix wins over provider defaults such as
# 50-cloud-init.conf, which often turn password login on.
echo "→ Turning off SSH password logins..."
printf 'PasswordAuthentication no\nKbdInteractiveAuthentication no\n' \
  | sudo tee /etc/ssh/sshd_config.d/00-openclaw-deploy.conf > /dev/null
sudo sshd -t
sudo systemctl try-reload-or-restart ssh
echo "✓ SSH accepts key logins only"

# Install OpenClaw (official installer)
echo "→ Installing OpenClaw..."
curl -fsSL https://openclaw.ai/install.sh | bash -s -- --no-prompt --no-onboard

export PATH="$HOME/.npm-global/bin:$HOME/.openclaw/bin:$PATH"
if ! command -v openclaw &> /dev/null; then
  echo "❌ OpenClaw installation failed"
  exit 1
fi
echo "✓ $(openclaw --version | head -1) installed"

# Keep the agent's background service running after logout and start it on
# boot. Onboarding only attempts this, so do it here (docs.openclaw.ai/start/setup).
sudo loginctl enable-linger "$USER"

# Onboarding with OpenClaw's defaults: connects Claude and installs and
# starts the gateway service
echo "→ Running OpenClaw onboarding..."
ONBOARD_ARGS=(
  --non-interactive
  --accept-risk
  --mode local
  --install-daemon
  --skip-skills
)
if [ "$AUTH_METHOD" = "apiKey" ]; then
  openclaw onboard "${ONBOARD_ARGS[@]}" --auth-choice apiKey --anthropic-api-key "$AUTH_VALUE"
elif [ "$AUTH_METHOD" = "token" ]; then
  openclaw onboard "${ONBOARD_ARGS[@]}" --auth-choice token --token-provider anthropic --token "$AUTH_VALUE"
else
  echo "❌ Invalid auth method: $AUTH_METHOD"
  exit 1
fi
echo "✓ Onboarding complete"

# Telegram: add the bot, and allow only your account to message it
echo "→ Configuring Telegram..."
openclaw channels add --channel telegram --token "$TELEGRAM_TOKEN"
openclaw config set channels.telegram.allowFrom "[\"$TELEGRAM_USER_ID\"]" --strict-json
openclaw config set channels.telegram.dmPolicy allowlist
openclaw config set commands.ownerAllowFrom "[\"telegram:$TELEGRAM_USER_ID\"]" --strict-json
echo "✓ Telegram configured (only user $TELEGRAM_USER_ID can message the bot)"

# Wait for the gateway to connect the bot, using OpenClaw's own live check
echo "→ Checking Telegram..."
BOT_USERNAME=""
for _ in $(seq 1 12); do
  BOT_USERNAME=$(openclaw channels status --channel telegram --probe --json 2>/dev/null | python3 -c '
import json, sys
t = json.load(sys.stdin).get("channels", {}).get("telegram", {})
p = t.get("probe") or {}
if t.get("running") and p.get("ok"):
    print((p.get("bot") or {}).get("username", ""))
' 2>/dev/null) || true
  [ -n "$BOT_USERNAME" ] && break
  sleep 5
done

if [ -z "$BOT_USERNAME" ]; then
  echo "❌ Your agent is installed, but its Telegram bot didn't come online."
  echo "Run ./deploy.sh again. If it happens again, open an issue:"
  echo "https://github.com/ortegarod/openclaw-vps-deploy/issues"
  exit 1
fi

echo ""
echo "========================================"
echo "✅ Setup complete"
echo "========================================"
echo ""
echo "Your agent is live. Message it on Telegram: https://t.me/$BOT_USERNAME"
echo "It only answers Telegram user $TELEGRAM_USER_ID. If it doesn't reply, check"
echo "your ID with @userinfobot and run ./deploy.sh again with the right one."
echo ""
echo "Configuration: $HOME/.openclaw/openclaw.json"
echo "Workspace:     $HOME/.openclaw/workspace"
echo ""
