# OpenClaw VPS Deployment

**One-command deployment of OpenClaw to any VPS.**

Deploy a production-ready OpenClaw instance to any Ubuntu VPS in ~10 minutes.

**Uses:** [Official OpenClaw installer](https://docs.openclaw.ai/install) (recommended method)

---

## Features

✅ Automated VPS setup (firewall, security)  
✅ Official OpenClaw installer  
✅ Telegram bot configuration  
✅ Workspace structure with defaults  
✅ Systemd service (auto-restart on crashes)  
✅ SSH access for maintenance  

---

## Prerequisites

You'll need these before starting:

1. **VPS** - Ubuntu 24.04 server from any provider (see step 1 below)
2. **SSH key** - For secure access to your VPS ([How to generate](https://docs.github.com/en/authentication/connecting-to-github-with-ssh/generating-a-new-ssh-key-and-adding-it-to-the-ssh-agent))
3. **Telegram bot token** - From @BotFather (see step 2 below)
4. **Claude API key** - From Anthropic Console (see step 3 below)

---

## Quick Start

**What you need:**
- A VPS (Virtual Private Server)
- Telegram bot token (from @BotFather)
- Claude API key (from Anthropic)

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

**Note:** You can use pay-as-you-go or your existing Claude subscription

### 4. Run the Deploy Script

```bash
git clone https://github.com/kali-claw/openclaw-vps-deploy.git
cd openclaw-vps-deploy

./deploy.sh \
  --host YOUR_VPS_IP \
  --telegram-token "YOUR_TELEGRAM_TOKEN" \
  --api-key "YOUR_CLAUDE_API_KEY"
```

Replace:
- `YOUR_VPS_IP` with your VPS IP from step 1
- `YOUR_TELEGRAM_TOKEN` with the token from step 2
- `YOUR_CLAUDE_API_KEY` with the key from step 3

### 5. Done!

The script will:
1. SSH into your VPS
2. Run the official OpenClaw installer
3. Configure firewall
4. Set up Telegram bot connection
5. Create workspace structure
6. Start the gateway as systemd service

**Your bot is now live on Telegram!**

---

## What Gets Deployed

### Directory Structure on VPS

```
/root/.openclaw/
├── bin/openclaw            # OpenClaw binary
├── config.json             # Configuration
└── workspace/
    ├── IDENTITY.md         # Agent identity
    ├── SOUL.md             # Personality/behavior
    ├── USER.md             # User info (customize this)
    ├── TOOLS.md            # Tools documentation
    ├── MEMORY.md           # Long-term memory
    └── memory/
        └── YYYY-MM-DD.md   # Daily logs
```

### Service

- **openclaw.service** - Systemd service (auto-restart)
- Runs as root
- Logs to journald

---

## Post-Deployment

### Customize the Agent

SSH into your VPS and edit workspace files:

```bash
ssh root@your-vps-ip

# Edit agent identity
nano /root/.openclaw/workspace/IDENTITY.md

# Edit personality
nano /root/.openclaw/workspace/SOUL.md

# Add user context
nano /root/.openclaw/workspace/USER.md
```

Restart to apply changes:
```bash
systemctl restart openclaw
```

### Check Logs

```bash
ssh root@your-vps-ip
journalctl -u openclaw -f
```

### Restart Gateway

```bash
ssh root@your-vps-ip
systemctl restart openclaw
```

### Update OpenClaw

```bash
ssh root@your-vps-ip
# Re-run the installer
curl -fsSL https://openclaw.ai/install.sh | bash
systemctl restart openclaw
```

---

## Configuration

### Custom Models

Edit `/root/.openclaw/config.json`:

```json
{
  "agents": {
    "defaults": {
      "model": {
        "primary": "anthropic/claude-opus-4-6"
      }
    }
  }
}
```

Then restart: `systemctl restart openclaw`

### Adding Channels

To add more channels (Discord, WhatsApp, etc.), edit `config.json` and restart.

See [OpenClaw channel docs](https://docs.openclaw.ai/channels).

---

## Troubleshooting

### Bot not responding

**Check if gateway is running:**
```bash
ssh root@your-vps-ip
systemctl status openclaw
```

**View logs:**
```bash
journalctl -u openclaw -f
```

**Restart:**
```bash
systemctl restart openclaw
```

### SSH connection refused

- Verify VPS is running in provider dashboard
- Check firewall allows port 22
- Verify SSH key is correct

### Telegram token invalid

- Double-check token from @BotFather
- Ensure no extra spaces or quotes
- Regenerate token if needed: `/token` in BotFather

---

## Security

The deployment script includes basic security:
- UFW firewall (SSH, HTTP, HTTPS only)
- Systemd service isolation

**Additional recommendations:**
- Change SSH port from 22
- Disable password auth (key-only)
- Set up fail2ban
- Enable automatic security updates

---



## Contributing

Contributions welcome! Please:
- Test on a clean VPS before submitting PR
- Follow existing script style
- Update README if adding features

---

## License

MIT License - See [LICENSE](LICENSE)

---

## Resources

- [OpenClaw Documentation](https://docs.openclaw.ai)
- [OpenClaw Discord](https://discord.com/invite/clawd)
- [OpenClaw GitHub](https://github.com/openclaw/openclaw)

---

## Credits

Built by [@kali-claw](https://github.com/kali-claw) to simplify OpenClaw VPS deployments.

---

**Questions?** Open an issue or ask in the [OpenClaw Discord](https://discord.com/invite/clawd).
