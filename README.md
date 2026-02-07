# OpenClaw VPS Deployment

**One-command deployment of OpenClaw to a VPS with Docker or direct install.**

Deploy a production-ready OpenClaw instance to any Ubuntu VPS in ~10 minutes.

**Based on:** [Official OpenClaw Hetzner Guide](https://docs.openclaw.ai/install/hetzner)

---

## Features

✅ **Two installation methods**: Docker or direct install  
✅ Automated server setup (firewall, security hardening)  
✅ Telegram bot configuration  
✅ Workspace structure with sensible defaults  
✅ Auto-restart on crashes (systemd or Docker restart policy)  
✅ SSH access for maintenance  

---

## Prerequisites

- **VPS**: Ubuntu 24.04 server (any provider: Hetzner, OVH, DigitalOcean, etc.)
- **SSH access**: Root access via SSH key
- **Telegram bot**: Token from @BotFather
- **API key**: Claude API key (Anthropic) or OpenRouter

---

## Quick Start

### 1. Create a VPS

**Recommended providers:**
- [Hetzner Cloud](https://www.hetzner.com/cloud) - CX22 (~€6/mo)
- [OVH](https://www.ovhcloud.com/) - VPS-1 (~$6/mo)
- [DigitalOcean](https://www.digitalocean.com/) - Basic Droplet ($6/mo)

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

### 3. Run the Deploy Script

```bash
git clone https://github.com/kali-claw/openclaw-vps-deploy.git
cd openclaw-vps-deploy

./deploy.sh \
  --host 203.0.113.45 \
  --telegram-token "123456789:ABCdefGHIjklMNOpqrsTUVwxyz" \
  --api-key "sk-ant-api03-..."
```

**Optional flags:**
```bash
--name "my-agent"              # Agent name (default: "openclaw-agent")
--model "claude-sonnet-4-5"    # Model (default: claude-sonnet-4-5)
--method docker                # docker (default) or direct
--user root                     # SSH user (default: root)
```

#### Installation Methods

**Docker (default):**
- Clones OpenClaw repository and builds from source
- Official method from OpenClaw docs
- Isolated container environment
- Supports all skills and custom binaries
- Recommended for production

**Direct:**
- Uses official OpenClaw installer (`install.sh`)
- Simpler architecture (no Docker layer)
- Managed by systemd service
- Better for understanding how OpenClaw works

Choose based on your preference:
```bash
# Docker (default)
./deploy.sh --host <ip> --telegram-token <token> --api-key <key>

# Direct install
./deploy.sh --host <ip> --telegram-token <token> --api-key <key> --method direct
```

### 4. Done!

The script will:
1. SSH into your VPS
2. Install Docker and dependencies
3. Configure firewall
4. Deploy OpenClaw via Docker Compose
5. Set up Telegram bot connection
6. Create workspace structure
7. Start the gateway

**Your bot is now live on Telegram!**

---

## What Gets Deployed

### Directory Structure on VPS

```
/root/openclaw/                 # OpenClaw repository (cloned from GitHub)
├── docker-compose.yml          # Container orchestration
├── .env                        # Environment variables (secrets)
├── Dockerfile                  # Image build instructions
└── ...                         # Source code

/root/.openclaw/
├── config.json                 # OpenClaw configuration
└── workspace/
    ├── IDENTITY.md             # Agent identity
    ├── SOUL.md                 # Personality/behavior
    ├── USER.md                 # User info (customize this)
    ├── TOOLS.md                # Tools documentation
    ├── MEMORY.md               # Long-term memory
    └── memory/
        └── YYYY-MM-DD.md       # Daily logs
```

**Why this structure:**
- `/root/openclaw/` - Source of truth for code (survives restarts)
- `/root/.openclaw/` - Persistent config & workspace (mounted into container)
- Container itself is ephemeral (safe to destroy)

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
cd /root/openclaw
docker compose restart openclaw-gateway
```

### Check Logs

**Docker:**
```bash
ssh root@your-vps-ip
cd /root/openclaw
docker compose logs -f openclaw-gateway
```

**Direct:**
```bash
ssh root@your-vps-ip
journalctl -u openclaw -f
```

### Restart Gateway

**Docker:**
```bash
ssh root@your-vps-ip
cd /root/openclaw
docker compose restart openclaw-gateway
```

**Direct:**
```bash
ssh root@your-vps-ip
systemctl restart openclaw
```

### Update OpenClaw

**Docker:**
```bash
ssh root@your-vps-ip
cd /root/openclaw
git pull
docker compose build
docker compose up -d openclaw-gateway
```

**Direct:**
```bash
ssh root@your-vps-ip
# Re-run the installer to get latest version
curl -fsSL https://openclaw.ai/install.sh | bash
systemctl restart openclaw
```

---

## Configuration

### Environment Variables

You can set these in `/opt/openclaw/.env` or pass via docker-compose:

```bash
OPENCLAW_GATEWAY_PORT=18789
OPENCLAW_LOG_LEVEL=info
NODE_ENV=production
```

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

### Adding Channels

To add more channels (Discord, WhatsApp, etc.), edit `config.json` and restart.

See [OpenClaw channel docs](https://docs.openclaw.ai/channels).

---

## Troubleshooting

### Bot not responding

**Check if gateway is running:**

Docker:
```bash
ssh root@your-vps-ip
cd /root/openclaw
docker compose ps
```

Direct:
```bash
ssh root@your-vps-ip
systemctl status openclaw
```

**View logs:**

Docker:
```bash
cd /root/openclaw
docker compose logs openclaw-gateway
```

Direct:
```bash
journalctl -u openclaw -f
```

**Restart:**

Docker:
```bash
cd /root/openclaw
docker compose restart openclaw-gateway
```

Direct:
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

## Security Hardening

The deployment script includes basic security:
- UFW firewall (SSH, HTTP, HTTPS only)
- Docker container isolation
- Non-root user for containers

**Additional recommendations:**
- Change SSH port from 22
- Disable password auth (key-only)
- Set up fail2ban
- Enable automatic security updates
- Use CloudFlare for DDoS protection

---

## Architecture

```
┌─────────────┐
│  Telegram   │
│    User     │
└──────┬──────┘
       │
       ▼
┌─────────────────────────────────┐
│         Telegram API            │
│   (webhook or long-polling)     │
└──────────────┬──────────────────┘
               │
               ▼
┌─────────────────────────────────┐
│           VPS                   │
│  ┌───────────────────────────┐  │
│  │  OpenClaw Gateway         │  │
│  │  (Docker container)       │  │
│  └───────────┬───────────────┘  │
│              │                   │
│              ▼                   │
│  ┌───────────────────────────┐  │
│  │  Claude API / OpenRouter  │  │
│  │  (via HTTPS)              │  │
│  └───────────────────────────┘  │
└─────────────────────────────────┘
```

---

## Cost Estimate

**VPS:** $6-10/month  
**Claude API:** ~$20-50/month (depends on usage)  
**Total:** ~$30-60/month for a personal/light-use agent

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
