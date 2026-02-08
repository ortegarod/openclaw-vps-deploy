# OpenClaw VPS Deployment

**Automated OpenClaw deployment to any Ubuntu VPS.**

Deploy a production-ready OpenClaw instance in ~10 minutes using the official OpenClaw installer and onboarding wizard.

**Uses:** [Official OpenClaw installer](https://docs.openclaw.ai/install) + [Onboarding wizard (non-interactive mode)](https://docs.openclaw.ai/reference/wizard#non-interactive-mode)

---

## Prerequisites

You'll need these before starting:

1. **VPS** - Ubuntu 24.04 server from any provider
2. **SSH access** - SSH key (recommended) or password
3. **Telegram bot token** - From @BotFather
4. **Claude API key** - From Anthropic Console

---

## Quick Start

### 1. Create a VPS

**Recommended providers:**
- [Hetzner Cloud](https://www.hetzner.com/cloud)
- [OVH](https://www.ovhcloud.com/)
- [DigitalOcean](https://www.digitalocean.com/)

**Specs:**
- OS: Ubuntu 24.04
- RAM: 4GB minimum
- Storage: 40GB+
- Add your SSH key during creation

### 2. Create a Telegram Bot

Message [@BotFather](https://t.me/botfather) on Telegram:

```
/newbot
[Follow the prompts]
```

Save the token (format: `123456789:ABCdefGHIjklMNOpqrsTUVwxyz`)

### 3. Get a Claude API Key

Go to [Anthropic Console](https://console.anthropic.com/):

1. Sign up or log in
2. Go to **API Keys** section
3. Click **Create Key**
4. Save the key (format: `sk-ant-api03-...`)

**Note:** The script uses API key authentication (pay-as-you-go billing)

### 4. Run the Deploy Script

```bash
git clone https://github.com/kali-claw/openclaw-vps-deploy.git
cd openclaw-vps-deploy

./deploy.sh \
  --host YOUR_VPS_IP \
  --user YOUR_SSH_USER \
  --telegram-token "YOUR_TELEGRAM_TOKEN" \
  --api-key "YOUR_CLAUDE_API_KEY"
```

**Or with Claude subscription setup-token:**

```bash
./deploy.sh \
  --host YOUR_VPS_IP \
  --user YOUR_SSH_USER \
  --telegram-token "YOUR_TELEGRAM_TOKEN" \
  --token "YOUR_SETUP_TOKEN"
```

Replace:
- `YOUR_VPS_IP` with your VPS IP address (e.g., `149.56.128.28`)
- `YOUR_SSH_USER` with your SSH username (e.g., `ubuntu`, `root`)
- `YOUR_TELEGRAM_TOKEN` with the token from step 2
- `YOUR_CLAUDE_API_KEY` with the API key from step 3 **OR**
- `YOUR_SETUP_TOKEN` with your Claude setup-token (run `claude setup-token` to generate)

**Important SSH notes:**
- Use the **IP address**, not the hostname (unless DNS is configured)
- Specify `--user` to match your SSH config (default is `root`)
- The script uses your existing SSH keys automatically
- If you have VS Code or SSH access working, use the same IP and user

### 5. Done!

The script will:
1. Install OpenClaw using the official installer
2. Run the onboarding wizard (non-interactive mode)
3. Configure Telegram channel
4. Install and start the OpenClaw daemon
5. Configure firewall

**Your bot is now live on Telegram!**

---

## What Gets Deployed

The script follows the official OpenClaw installation process:

1. **Installs OpenClaw** via `curl -fsSL https://openclaw.ai/install.sh | bash`
2. **Runs onboarding** via `openclaw onboard --non-interactive` with your settings
3. **Adds Telegram** via `openclaw channels add --channel telegram`
4. **Installs daemon** systemd service for auto-restart

### Directory Structure

```
/root/.openclaw/
├── bin/openclaw            # OpenClaw binary
├── openclaw.json           # Configuration
└── workspace/              # Agent workspace
    ├── AGENTS.md
    ├── IDENTITY.md
    ├── SOUL.md
    └── ...
```

---

## Post-Deployment

### Customize the Agent

SSH into your VPS and edit workspace files:

```bash
ssh root@your-vps-ip
nano /root/.openclaw/workspace/IDENTITY.md
nano /root/.openclaw/workspace/SOUL.md
```

Restart to apply changes:
```bash
openclaw gateway restart
```

### Check Status

```bash
ssh root@your-vps-ip
openclaw status
```

### View Logs

```bash
openclaw logs
```

### Restart Gateway

```bash
openclaw gateway restart
```

### Update OpenClaw

```bash
# Re-run the installer
curl -fsSL https://openclaw.ai/install.sh | bash
openclaw gateway restart
```

---

## Troubleshooting

### SSH connection fails

If you see "Permission denied" or "Cannot connect":

1. **Check your SSH config** (`~/.ssh/config`) if you use VS Code or similar tools
2. **Use the same IP and user** that works in your SSH client:
   ```bash
   ./deploy.sh --host YOUR_IP --user YOUR_USER --telegram-token "..." --token "..."
   ```
3. **Test SSH manually first:**
   ```bash
   ssh YOUR_USER@YOUR_IP
   ```

### Bot not responding

```bash
ssh YOUR_USER@YOUR_IP
openclaw status
openclaw logs
```

### Gateway not running

```bash
openclaw gateway start
```

### Check Telegram configuration

```bash
openclaw channels list
```

---

## Security

The deployment includes:
- UFW firewall (SSH, HTTP, HTTPS, Gateway port)
- Systemd service isolation

**Additional recommendations:**
- Change SSH port from 22
- Disable password auth (key-only)
- Set up fail2ban

---

## Documentation

- [OpenClaw Documentation](https://docs.openclaw.ai)
- [Onboarding Wizard](https://docs.openclaw.ai/start/wizard)
- [CLI Reference](https://docs.openclaw.ai/cli)
- [Channels](https://docs.openclaw.ai/channels)

---

## Contributing

Contributions welcome! Please test on a clean VPS before submitting PR.

---

## License

MIT License - See [LICENSE](LICENSE)

---

## Credits

Built by [@kali-claw](https://github.com/kali-claw) using official OpenClaw methods.

**Questions?** [OpenClaw Discord](https://discord.com/invite/clawd)
