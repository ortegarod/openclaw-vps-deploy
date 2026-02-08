# OpenClaw VPS Deployment

**One-command deployment of OpenClaw to any Ubuntu VPS.**

Automated deployment script using the [official OpenClaw installer](https://docs.openclaw.ai/install). Deploy in ~10 minutes with two modes:

1. **Fully Configured** — Provide credentials, bot ready immediately
2. **Install Only** — Install OpenClaw, configure interactively later

---

## Use Cases

- 🏠 **Personal use** — Deploy your own AI assistant on a VPS
- 💼 **Managed services** — Deploy pre-configured instances for clients
- 🧪 **Development** — Quick testing environment on a fresh VPS
- 👥 **Team deployments** — Provision infrastructure, let users configure their own credentials

---

## Prerequisites

**For all deployments:**
- Ubuntu 24.04 VPS (4GB RAM minimum, 40GB+ storage)
- SSH access (key-based recommended)

**For fully configured deployments (optional):**
- Telegram bot token from [@BotFather](https://t.me/botfather)
- User's Telegram ID (get via [@userinfobot](https://t.me/userinfobot))
- Anthropic API key or Claude setup-token

---

## Quick Start

### Install-Only Mode (Simplest)

Install OpenClaw, user configures their own credentials:

```bash
git clone https://github.com/kali-claw/openclaw-vps-deploy.git
cd openclaw-vps-deploy

./deploy.sh --host YOUR_VPS_IP --user YOUR_SSH_USER
```

Then SSH in and run the interactive wizard:
```bash
ssh YOUR_SSH_USER@YOUR_VPS_IP
openclaw onboard
```

---

### Fully Configured Mode (Turn-Key)

Provide all credentials upfront, bot ready immediately:

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

**Fresh installation (wipe existing data):**
```bash
./deploy.sh \
  --host YOUR_VPS_IP \
  --user YOUR_SSH_USER \
  --telegram-token "..." \
  --telegram-user-id ... \
  --token "..." \
  --clean
```

The `--clean` flag removes existing workspace/identity files before deployment. Use when redeploying to an existing VPS.

---

## Command Reference

### Required Flags

- `--host <ip>` — VPS IP address (e.g., `149.56.128.28`)
- `--user <user>` — SSH username (e.g., `ubuntu`, `root`)

### Optional Flags (Fully Configured Mode)

When any of these are provided, the script runs in **fully configured mode** and requires all credential flags:

- `--telegram-token <token>` — Bot token from @BotFather
- `--telegram-user-id <id>` — User's Telegram ID (e.g., `1273064446`)
- `--api-key <key>` — Anthropic API key (`sk-ant-...`)
- `--token <token>` — Claude setup-token (from `claude setup-token`)

### Additional Options

- `--name <name>` — Agent name (default: `openclaw-agent`)
- `--model <model>` — Model to use (default: `anthropic/claude-sonnet-4-5`)
- `--clean` — Wipe existing workspace before deployment (fresh start)

---

## What Gets Installed

The script installs:

1. **OpenClaw CLI** — Via official installer (`curl -fsSL https://openclaw.ai/install.sh | bash`)
2. **System packages** — curl, git, ufw (firewall)
3. **Firewall rules** — SSH (22), HTTP (80), HTTPS (443), Gateway (18789)

### In Fully Configured Mode

Additionally configures:
4. **Onboarding** — Non-interactive setup with provided credentials
5. **Telegram channel** — Pre-authorized for specified user ID
6. **Gateway daemon** — Auto-starts via systemd

### Directory Structure

```
~/.openclaw/
├── bin/openclaw              # OpenClaw CLI
├── openclaw.json             # Configuration
├── workspace/                # Agent workspace (SOUL.md, IDENTITY.md, etc.)
├── agents/main/sessions/     # Session history
└── credentials/              # Channel credentials
```

---

## Post-Deployment

### Install-Only Mode

SSH into the VPS and complete setup:

```bash
ssh YOUR_SSH_USER@YOUR_VPS_IP
openclaw onboard  # Interactive wizard
```

The wizard will guide you through:
- Authentication (API key or setup-token)
- Model selection
- Channel configuration (Telegram, WhatsApp, etc.)
- Daemon installation

### Fully Configured Mode

The bot is ready immediately! User can:
- Message the bot on Telegram (pre-authorized)
- Check status: `ssh YOUR_SSH_USER@YOUR_VPS_IP 'openclaw status'`
- View logs: `ssh YOUR_SSH_USER@YOUR_VPS_IP 'openclaw logs --follow'`

---

## VPS Providers

**Recommended:**

- **[Hetzner Cloud](https://www.hetzner.com/cloud)** — €4.51/mo for 4GB RAM
- **[OVH](https://www.ovhcloud.com/)** — Budget-friendly VPS options
- **[DigitalOcean](https://www.digitalocean.com/)** — $24/mo for 4GB RAM

**Minimum specs:**
- 4GB RAM
- 40GB+ storage
- Ubuntu 24.04

---

## Troubleshooting

### SSH Connection Issues

If deployment fails to connect:

1. **Verify SSH access works manually:**
   ```bash
   ssh YOUR_USER@YOUR_IP
   ```

2. **Use the same IP/user** that works in your SSH client:
   ```bash
   ./deploy.sh --host YOUR_IP --user YOUR_USER
   ```

3. **Check your SSH config** (`~/.ssh/config`) if you use VS Code or similar tools

### Bot Not Responding

```bash
ssh YOUR_USER@YOUR_IP
openclaw status
openclaw logs --follow
```

### Gateway Not Running

```bash
openclaw gateway start
```

### Check Telegram Configuration

```bash
openclaw channels list
```

---

## Security Notes

**The script deploys OpenClaw with:**
- ✅ Firewall enabled (UFW)
- ✅ DM pairing or allowlist (not open by default)
- ✅ Group mention gating (bot only responds when mentioned)

**For production deployments:**
- Use SSH keys (not passwords)
- Keep the VPS updated: `sudo apt update && sudo apt upgrade`
- Review [OpenClaw security docs](https://docs.openclaw.ai/security)
- Run security audit: `openclaw security audit`

---

## Examples

### Personal Assistant Deployment

```bash
# Install only, configure your own credentials
./deploy.sh --host 149.56.128.28 --user ubuntu
```

### Managed Service Deployment

```bash
# Fully configured for a client
./deploy.sh \
  --host 149.56.128.28 \
  --user ubuntu \
  --telegram-token "123456:ABCdef..." \
  --telegram-user-id 987654321 \
  --api-key "sk-ant-api03-..."
```

### Fresh Re-deployment

```bash
# Wipe existing workspace and redeploy
./deploy.sh \
  --host 149.56.128.28 \
  --user ubuntu \
  --telegram-token "..." \
  --telegram-user-id ... \
  --token "..." \
  --clean
```

---

## Documentation

- [OpenClaw Docs](https://docs.openclaw.ai)
- [Installation Guide](https://docs.openclaw.ai/install)
- [Onboarding Wizard](https://docs.openclaw.ai/start/wizard)
- [Channels](https://docs.openclaw.ai/channels)
- [Security](https://docs.openclaw.ai/security)

---

## Contributing

Contributions welcome! This script uses only officially documented OpenClaw CLI commands.

**To contribute:**
1. Test on a clean Ubuntu 24.04 VPS
2. Verify both deployment modes work
3. Update README if adding new flags
4. Submit a pull request

---

## License

MIT License - See [LICENSE](LICENSE)

---

## Credits

Built using the [official OpenClaw installer](https://openclaw.ai/install.sh) and [documented CLI commands](https://docs.openclaw.ai/cli).

**Questions?** [OpenClaw Discord](https://discord.com/invite/clawd)
