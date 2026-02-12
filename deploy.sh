#!/bin/bash
#
# deploy.sh - Deploy OpenClaw to a VPS
#
# Usage:
#   ./deploy.sh --host <ip> --telegram-token <token> --api-key <key> [options]
#

set -e

# Default values
SSH_USER="root"
AGENT_NAME="openclaw-agent"
MODEL="anthropic/claude-sonnet-4-5"
AUTH_METHOD=""
AUTH_VALUE=""
TELEGRAM_TOKEN=""
TELEGRAM_USER_ID=""
CLEAN_INSTALL=""

# Parse arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    --host)
      VPS_HOST="$2"
      shift 2
      ;;
    --user)
      SSH_USER="$2"
      shift 2
      ;;
    --telegram-token)
      TELEGRAM_TOKEN="$2"
      shift 2
      ;;
    --telegram-user-id)
      TELEGRAM_USER_ID="$2"
      shift 2
      ;;
    --api-key)
      AUTH_METHOD="apiKey"
      AUTH_VALUE="$2"
      shift 2
      ;;
    --token)
      AUTH_METHOD="token"
      AUTH_VALUE="$2"
      shift 2
      ;;
    --name)
      AGENT_NAME="$2"
      shift 2
      ;;
    --model)
      MODEL="$2"
      shift 2
      ;;
    --clean)
      CLEAN_INSTALL="true"
      shift
      ;;
    -h|--help)
      echo "Usage: $0 --host <ip> --user <user> [--telegram-token <token> --telegram-user-id <id> (--api-key <key> | --token <token>)] [options]"
      echo ""
      echo "Required:"
      echo "  --host <ip>               VPS IP address (e.g., 149.56.128.28)"
      echo "  --user <user>             SSH username (e.g., ubuntu, root)"
      echo ""
      echo "Optional (Managed Deployment - Fully Configured):"
      echo "  --telegram-token <token>  Telegram bot token from @BotFather"
      echo "  --telegram-user-id <id>   Customer's Telegram user ID (e.g., 1273064446)"
      echo "  --api-key <key>           Anthropic API key (sk-ant-...)"
      echo "  --token <token>           Claude setup-token (from 'claude setup-token')"
      echo "  --name <name>             Agent name (default: openclaw-agent)"
      echo "  --model <model>           Model to use (default: anthropic/claude-sonnet-4-5)"
      echo "  --clean                   Wipe existing workspace before deployment (fresh start)"
      echo ""
      echo "Deployment Modes:"
      echo "  1. Self-Service (no credentials): Just install OpenClaw, customer configures"
      echo "  2. Managed (with credentials): Fully configured, customer can use immediately"
      echo ""
      echo "Self-Service: Customer runs 'openclaw onboard' after SSH"
      echo "Managed: Provide all flags for turn-key deployment"
      echo "Managed + --clean: Fresh installation, removes old identity/workspace"
      echo ""
      exit 0
      ;;
    *)
      echo "Unknown option: $1"
      echo "Run with -h or --help for usage"
      exit 1
      ;;
  esac
done

# Validate required args
if [ -z "$VPS_HOST" ]; then
  echo "❌ Error: Missing required arguments"
  echo ""
  echo "Usage: $0 --host <ip> --user <user>"
  echo "Run with -h or --help for full usage"
  exit 1
fi

# Check if managed or self-service mode
if [ -n "$TELEGRAM_TOKEN" ] || [ -n "$AUTH_VALUE" ]; then
  # Managed mode - validate all required credentials
  if [ -z "$TELEGRAM_TOKEN" ] || [ -z "$TELEGRAM_USER_ID" ] || [ -z "$AUTH_VALUE" ]; then
    echo "❌ Error: Managed deployment requires all credentials"
    echo ""
    echo "For managed deployment, provide:"
    echo "  --telegram-token, --telegram-user-id, and (--api-key OR --token)"
    echo ""
    echo "Or omit credentials for self-service mode (customer configures later)"
    exit 1
  fi
  DEPLOYMENT_MODE="managed"
else
  DEPLOYMENT_MODE="self-service"
fi

echo "=========================================="
echo "OpenClaw VPS Deployment"
echo "=========================================="
echo "Host: $VPS_HOST"
echo "Agent: $AGENT_NAME"
echo "Model: $MODEL"
echo "SSH User: $SSH_USER"
echo "=========================================="
echo ""

# Test SSH connection
echo "→ Testing SSH connection..."
if ! ssh -o ConnectTimeout=10 "$SSH_USER@$VPS_HOST" "echo 'SSH OK'"; then
  echo "❌ Cannot connect to $SSH_USER@$VPS_HOST"
  echo ""
  echo "Please ensure:"
  echo "  1. VPS is running"
  echo "  2. IP address is correct"
  echo "  3. SSH access is configured (key or password)"
  exit 1
fi

echo "✓ SSH connection successful"
echo ""

# Copy setup script to VPS
echo "→ Copying setup script to VPS..."
scp -q "$(dirname "$0")/vps-setup.sh" "$SSH_USER@$VPS_HOST:/tmp/"

# Run setup on VPS
if [ "$DEPLOYMENT_MODE" = "managed" ]; then
  echo "→ Running MANAGED deployment (fully configured)..."
  if [ "$CLEAN_INSTALL" = "true" ]; then
    echo "→ Clean install enabled (will wipe existing workspace)"
  fi
else
  echo "→ Running SELF-SERVICE deployment (install only)..."
fi
echo ""

ssh -t "$SSH_USER@$VPS_HOST" "bash /tmp/vps-setup.sh '$DEPLOYMENT_MODE' '$CLEAN_INSTALL' '$AGENT_NAME' '$TELEGRAM_TOKEN' '$TELEGRAM_USER_ID' '$AUTH_METHOD' '$AUTH_VALUE' '$MODEL'"

# Done
echo ""
echo "=========================================="
echo "✅ Deployment Complete!"
echo "=========================================="
echo ""
echo "Your OpenClaw agent is now running at:"
echo "  VPS: $VPS_HOST"
echo "  Telegram: https://t.me/$(echo "$TELEGRAM_TOKEN" | cut -d: -f1)"
echo ""
echo "Next steps:"
echo "  1. Send a message to your Telegram bot to test it"
echo "  2. Customize agent: ssh $SSH_USER@$VPS_HOST"
echo "  3. Edit files in: /root/.openclaw/workspace/"
echo ""
echo "Useful commands:"
echo "  Check status: ssh $SSH_USER@$VPS_HOST 'openclaw status'"
echo "  View logs: ssh $SSH_USER@$VPS_HOST 'openclaw logs --follow'"
echo "  Restart: ssh $SSH_USER@$VPS_HOST 'openclaw gateway restart'"
echo "  Diagnostics: ssh $SSH_USER@$VPS_HOST 'openclaw doctor'"
echo ""
echo "🎉 Your agent is live!"
