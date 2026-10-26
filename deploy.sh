#!/bin/bash
#
# deploy.sh - Deploy a personal OpenClaw agent to a fresh Ubuntu VPS
#
# Run this on your own computer. It connects to the VPS over SSH, copies
# vps-setup.sh, and runs it there. Anything you don't pass as a flag, it asks for.
#
# Usage:
#   ./deploy.sh
#   ./deploy.sh --host <ip> --telegram-token <token> --telegram-user-id <id> (--api-key <key> | --token <token>)
#

set -e

SSH_USER="ubuntu"
VPS_HOST=""
TELEGRAM_TOKEN=""
TELEGRAM_USER_ID=""
AUTH_METHOD=""
AUTH_VALUE=""

usage() {
  echo "Usage: $0 [options]"
  echo ""
  echo "Any value you leave out, the script asks for."
  echo ""
  echo "  --host <ip>               VPS IP address"
  echo "  --user <user>             SSH username (default: ubuntu)"
  echo "  --telegram-token <token>  Telegram bot token from @BotFather"
  echo "  --telegram-user-id <id>   Your Telegram user ID from @userinfobot"
  echo "  --api-key <key>           Anthropic API key (sk-ant-api...)"
  echo "  --token <token>           Claude subscription setup-token (sk-ant-oat..., from 'claude setup-token')"
}

while [[ $# -gt 0 ]]; do
  case $1 in
    --host) VPS_HOST="$2"; shift 2 ;;
    --user) SSH_USER="$2"; shift 2 ;;
    --telegram-token) TELEGRAM_TOKEN="$2"; shift 2 ;;
    --telegram-user-id) TELEGRAM_USER_ID="$2"; shift 2 ;;
    --api-key) AUTH_METHOD="apiKey"; AUTH_VALUE="$2"; shift 2 ;;
    --token) AUTH_METHOD="token"; AUTH_VALUE="$2"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown option: $1"; echo "Run with --help for usage"; exit 1 ;;
  esac
done

# Read a hidden value, without spaces or line breaks. Fails if input ends.
read_secret() {
  local value
  read -r -s -p "$1" value || { echo >&2; return 1; }
  echo >&2
  printf '%s' "$value" | tr -d '[:space:]'
}

# claude setup-token prints the token over two lines, so a copied token can
# arrive in pieces. Join every line until an empty one (the second Enter).
read_setup_token() {
  local value more
  value=$(read_secret "$1") || return 1
  while read -r -s more; do
    more=$(printf '%s' "$more" | tr -d '[:space:]')
    [ -z "$more" ] && break
    value="$value$more"
  done
  printf '%s' "$value"
}

# Key checks, run before anything touches the VPS. Each prints what's wrong,
# or nothing if the key is good. Keys go to curl on stdin, not the command line.
check_telegram_token() {
  local code
  code=$(printf 'url = "https://api.telegram.org/bot%s/getMe"\n' "$1" \
    | curl -sS -o /dev/null -w '%{http_code}' -K - 2>/dev/null) || true
  case "$code" in
    200) ;;
    401|404) echo "Telegram doesn't recognize that bot token." ;;
    000) echo "Couldn't reach Telegram. Check your internet connection." ;;
    *) echo "Telegram returned an error ($code). Wait a minute." ;;
  esac
}
check_api_key() {
  local code
  code=$(printf 'header = "x-api-key: %s"\n' "$1" \
    | curl -sS -o /dev/null -w '%{http_code}' -K - -H "anthropic-version: 2023-06-01" \
      https://api.anthropic.com/v1/models 2>/dev/null) || true
  case "$code" in
    200) ;;
    401|403) echo "Anthropic doesn't recognize that API key." ;;
    000) echo "Couldn't reach Anthropic. Check your internet connection." ;;
    *) echo "Anthropic returned an error ($code). Wait a minute." ;;
  esac
}
# Same check OpenClaw's onboarding runs on a setup-token
check_setup_token() {
  case "$1" in
    sk-ant-oat01-*) [ ${#1} -ge 80 ] || echo "That setup-token is cut off. Copy all of it." ;;
    *) echo "A setup-token starts with sk-ant-oat01-." ;;
  esac
}

# Ask for a key until it passes its check: ask_secret <prompt> <check> [reader]
ask_secret() {
  local value problem
  while true; do
    value=$(${3:-read_secret} "$1") || exit 1
    problem=$($2 "$value")
    [ -z "$problem" ] && break
    echo "❌ $problem Try again." >&2
  done
  printf '%s' "$value"
}

# Ask for anything missing
if [ -z "$VPS_HOST" ]; then
  read -r -p "VPS IP address: " VPS_HOST
fi
if [ -z "$TELEGRAM_TOKEN" ]; then
  TELEGRAM_TOKEN=$(ask_secret "Telegram bot token (from @BotFather): " check_telegram_token)
fi
if [ -z "$TELEGRAM_USER_ID" ]; then
  read -r -p "Your Telegram user ID (from @userinfobot): " TELEGRAM_USER_ID
fi
if [ -z "$AUTH_VALUE" ]; then
  echo "How should your agent connect to Claude?"
  echo "  1) Anthropic API key"
  echo "  2) Claude subscription (setup-token from 'claude setup-token')"
  read -r -p "Choose 1 or 2: " AUTH_CHOICE
  case "$AUTH_CHOICE" in
    1) AUTH_METHOD="apiKey"; AUTH_VALUE=$(ask_secret "Anthropic API key: " check_api_key) ;;
    2) AUTH_METHOD="token"; AUTH_VALUE=$(ask_secret "Setup-token (paste it, then press Enter twice): " check_setup_token read_setup_token) ;;
    *) echo "❌ Please choose 1 or 2"; exit 1 ;;
  esac
fi

if [ -z "$VPS_HOST" ] || [ -z "$TELEGRAM_TOKEN" ] || [ -z "$TELEGRAM_USER_ID" ] || [ -z "$AUTH_VALUE" ]; then
  echo "❌ Missing a required value. Run with --help for usage."
  exit 1
fi
if ! [[ "$TELEGRAM_USER_ID" =~ ^[0-9]+$ ]]; then
  echo "❌ Telegram user ID should be a number (e.g. 987654321). @userinfobot shows it."
  exit 1
fi

# Keys passed as flags skip the prompts, so check them here too
if [ "$AUTH_METHOD" = "apiKey" ]; then
  PROBLEM=$(check_api_key "$AUTH_VALUE")
else
  PROBLEM=$(check_setup_token "$AUTH_VALUE")
fi
PROBLEM="${PROBLEM:-$(check_telegram_token "$TELEGRAM_TOKEN")}"
if [ -n "$PROBLEM" ]; then
  echo "❌ $PROBLEM"
  exit 1
fi

echo ""
echo "=========================================="
echo "OpenClaw VPS Deployment"
echo "=========================================="
echo "Host: $SSH_USER@$VPS_HOST"
echo "=========================================="
echo ""

echo "→ Testing SSH connection..."
if ! ssh -o BatchMode=yes -o ConnectTimeout=10 "$SSH_USER@$VPS_HOST" "echo 'SSH OK'" > /dev/null; then
  echo "❌ Cannot log in to $SSH_USER@$VPS_HOST without a password."
  echo ""
  echo "Check that:"
  echo "  1. The VPS is running and the IP is correct"
  echo "  2. 'ssh $SSH_USER@$VPS_HOST' logs you in without asking for a password"
  echo "     (set it up with: ssh-copy-id $SSH_USER@$VPS_HOST)"
  exit 1
fi
echo "✓ SSH connection successful"

echo "→ Copying setup script to VPS..."
scp -q "$(dirname "$0")/vps-setup.sh" "$SSH_USER@$VPS_HOST:/tmp/vps-setup.sh"

# Hand credentials over in a private file instead of on the ssh command line.
# vps-setup.sh deletes it once read.
ssh "$SSH_USER@$VPS_HOST" "umask 077; cat > /tmp/openclaw-deploy.env" <<EOF
TELEGRAM_TOKEN=$(printf '%q' "$TELEGRAM_TOKEN")
TELEGRAM_USER_ID=$(printf '%q' "$TELEGRAM_USER_ID")
AUTH_METHOD=$(printf '%q' "$AUTH_METHOD")
AUTH_VALUE=$(printf '%q' "$AUTH_VALUE")
EOF

echo "→ Running setup on the VPS (this takes several minutes)..."
echo ""
ssh -t "$SSH_USER@$VPS_HOST" \
  "bash /tmp/vps-setup.sh /tmp/openclaw-deploy.env; rc=\$?; rm -f /tmp/vps-setup.sh /tmp/openclaw-deploy.env; exit \$rc"

echo ""
echo "=========================================="
echo "✅ Deployment complete"
echo "=========================================="
echo ""
