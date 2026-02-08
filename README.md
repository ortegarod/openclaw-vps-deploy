# OpenClaw VPS Deployment

**Automated OpenClaw deployment to any Ubuntu VPS.**

Deploy in ~10 minutes using the [official OpenClaw installer](https://docs.openclaw.ai/install).

---

## Quick Start

### Install Only

```bash
git clone https://github.com/kali-claw/openclaw-vps-deploy.git
cd openclaw-vps-deploy

./deploy.sh --host YOUR_VPS_IP --user YOUR_SSH_USER
```

Then SSH in and configure:
```bash
ssh YOUR_SSH_USER@YOUR_VPS_IP
openclaw onboard
```

---

### Fully Configured

```bash
./deploy.sh \
  --host YOUR_VPS_IP \
  --user YOUR_SSH_USER \
  --telegram-token "TELEGRAM_BOT_TOKEN" \
  --telegram-user-id TELEGRAM_USER_ID \
  --api-key "ANTHROPIC_API_KEY"
```

**Or with Claude subscription:**
```bash
./deploy.sh \
  --host YOUR_VPS_IP \
  --user YOUR_SSH_USER \
  --telegram-token "TELEGRAM_BOT_TOKEN" \
  --telegram-user-id TELEGRAM_USER_ID \
  --token "CLAUDE_SETUP_TOKEN"
```

**Fresh install (wipe existing data):**

Add `--clean` to remove existing workspace:
```bash
./deploy.sh ... --clean
```

---

## Prerequisites

- Ubuntu 24.04 VPS (4GB RAM, 40GB+ storage)
- SSH access

**For fully configured mode:**
- Telegram bot token ([@BotFather](https://t.me/botfather))
- User's Telegram ID ([@userinfobot](https://t.me/userinfobot))
- Anthropic API key or Claude setup-token

---

## Options

### Required
- `--host <ip>` — VPS IP address
- `--user <user>` — SSH username

### Optional (Fully Configured Mode)
- `--telegram-token <token>` — Bot token
- `--telegram-user-id <id>` — User's Telegram ID
- `--api-key <key>` — Anthropic API key
- `--token <token>` — Claude setup-token
- `--name <name>` — Agent name (default: openclaw-agent)
- `--model <model>` — Model (default: anthropic/claude-sonnet-4-5)
- `--clean` — Wipe existing workspace

---

## What Gets Installed

- OpenClaw CLI (official installer)
- System packages (curl, git, ufw)
- Firewall rules (SSH, HTTP, HTTPS, Gateway)

**In fully configured mode:**
- Non-interactive onboarding
- Telegram channel (pre-authorized)
- Gateway daemon (systemd)

---

## Troubleshooting

### Check status
```bash
ssh YOUR_USER@YOUR_IP 'openclaw status'
```

### View logs
```bash
ssh YOUR_USER@YOUR_IP 'openclaw logs --follow'
```

### Restart gateway
```bash
ssh YOUR_USER@YOUR_IP 'openclaw gateway restart'
```

---

## Documentation

- [OpenClaw Docs](https://docs.openclaw.ai)
- [Installation](https://docs.openclaw.ai/install)
- [Channels](https://docs.openclaw.ai/channels)
- [Security](https://docs.openclaw.ai/security)

---

## License

MIT
