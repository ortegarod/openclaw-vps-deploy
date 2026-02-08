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

# Parse arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    --host)
      VPS_HOST="$2"
      shift 2
      ;;
    --telegram-token)
      TELEGRAM_TOKEN="$2"
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
    --user)
      SSH_USER="$2"
      shift 2
      ;;
    -h|--help)
      echo "Usage: $0 --host <ip> --user <user> --telegram-token <token> (--api-key <key> | --token <setup-token>) [options]"
      echo ""
      echo "Required:"
      echo "  --host <ip>               VPS IP address (e.g., 149.56.128.28)"
      echo "  --user <user>             SSH username (e.g., ubuntu, root)"
      echo "  --telegram-token <token>  Telegram bot token from @BotFather"
      echo ""
      echo "Auth (choose one):"
      echo "  --api-key <key>           Anthropic API key (sk-ant-...)"
      echo "  --token <token>           Claude setup-token (from 'claude setup-token')"
      echo ""
      echo "Optional:"
      echo "  --name <name>             Agent name (default: openclaw-agent)"
      echo "  --model <model>           Model to use (default: anthropic/claude-sonnet-4-5)"
      echo ""
      echo "Note: Use the same IP and user that works in your SSH client/VS Code"
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
if [ -z "$VPS_HOST" ] || [ -z "$TELEGRAM_TOKEN" ] || [ -z "$AUTH_VALUE" ]; then
  echo "❌ Error: Missing required arguments"
  echo ""
  echo "Usage: $0 --host <ip> --telegram-token <token> (--api-key <key> | --token <setup-token>)"
  echo "Run with -h or --help for full usage"
  exit 1
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
echo "→ Running deployment on VPS (this takes 5-10 minutes)..."
echo ""

ssh "$SSH_USER@$VPS_HOST" "bash /tmp/vps-setup.sh '$AGENT_NAME' '$TELEGRAM_TOKEN' '$AUTH_METHOD' '$AUTH_VALUE' '$MODEL'"

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
