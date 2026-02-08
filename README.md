# OpenClaw VPS Deployment

**Automated OpenClaw deployment to any Ubuntu VPS.**

Deploy OpenClaw in ~10 minutes using the official installer. Two modes available:

1. **Managed Deployment** (turn-key): Fully configured, bot ready immediately
2. **Self-Service Deployment**: Just install OpenClaw, customer configures via `openclaw onboard`

**Uses:** [Official OpenClaw installer](https://docs.openclaw.ai/install) + [Onboarding wizard](https://docs.openclaw.ai/reference/wizard)

---

## Prerequisites

You'll need these before starting:

1. **VPS** - Ubuntu 24.04 server from any provider
2. **SSH access** - SSH key (recommended) or password
3. **Telegram bot token** - From @BotFather
4. **Claude API key** - From Anthropic Console

---

## Quick Start

Choose your deployment mode:

- **[Managed Deployment](#managed-deployment-turn-key)** - You handle everything, customer gets working bot
- **[Self-Service Deployment](#self-service-deployment)** - Just install, customer configures

---

## Managed Deployment (Turn-Key)

Use this when deploying for customers and handling all configuration.

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

### 2.5 Get Customer's Telegram User ID

The customer can find their Telegram user ID by messaging [@userinfobot](https://t.me/userinfobot) on Telegram.

It will reply with their user ID (format: `1273064446`)

**Note:** You need this to pre-authorize the customer so they can message the bot immediately after deployment.

### 3. Get a Claude API Key

Go to [Anthropic Console](https://console.anthropic.com/):

1. Sign up or log in
2. Go to **API Keys** section
3. Click **Create Key**
4. Save the key (format: `sk-ant-api03-...`)

**Note:** The script uses API key authentication (pay-as-you-go billing)

### 4. Run the Deploy Script

**With API Key:**

```bash
git clone https://github.com/kali-claw/openclaw-vps-deploy.git
cd openclaw-vps-deploy

./deploy.sh \
  --host YOUR_VPS_IP \
  --user YOUR_SSH_USER \
  --telegram-token "YOUR_TELEGRAM_TOKEN" \
  --telegram-user-id YOUR_CUSTOMER_TELEGRAM_ID \
  --api-key "YOUR_CLAUDE_API_KEY"
```

**Or with Claude subscription setup-token:**

```bash
./deploy.sh \
  --host YOUR_VPS_IP \
  --user YOUR_SSH_USER \
  --telegram-token "YOUR_TELEGRAM_TOKEN" \
  --telegram-user-id YOUR_CUSTOMER_TELEGRAM_ID \
  --token "YOUR_SETUP_TOKEN"
```

**Fresh installation (wipe existing workspace):**

Add `--clean` to any managed deployment to remove existing identity/workspace files:

```bash
./deploy.sh \
  --host YOUR_VPS_IP \
  --user YOUR_SSH_USER \
  --telegram-token "YOUR_TELEGRAM_TOKEN" \
  --telegram-user-id YOUR_CUSTOMER_TELEGRAM_ID \
  --token "YOUR_SETUP_TOKEN" \
  --clean
```

**Use `--clean` when:**
- Redeploying to an existing VPS
- Customer wants a fresh start
- Previous bot identity should be removed

Replace:
- `YOUR_VPS_IP` with your VPS IP address (e.g., `149.56.128.28`)
- `YOUR_SSH_USER` with your SSH username (e.g., `ubuntu`, `root`)
- `YOUR_TELEGRAM_TOKEN` with the bot token from step 2
- `YOUR_CUSTOMER_TELEGRAM_ID` with the customer's Telegram user ID from step 2.5 (e.g., `1273064446`)
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
3. Configure Telegram channel with customer pre-authorized
4. Install and start the OpenClaw daemon
5. Configure firewall

**Your bot is now live on Telegram!**

The customer can message the bot immediately (no pairing approval needed) because their Telegram user ID was pre-authorized during deployment.

---

## Self-Service Deployment

Use this when customers will configure their own credentials. You just provision the VPS and install OpenClaw.

### 1. Create a VPS

Same as managed deployment (see above).

### 2. Run the Deploy Script (No Credentials)

```bash
git clone https://github.com/kali-claw/openclaw-vps-deploy.git
cd openclaw-vps-deploy

./deploy.sh \
  --host YOUR_VPS_IP \
  --user YOUR_SSH_USER
```

**That's it!** The script installs:
- OpenClaw CLI
- System dependencies (curl, git, ufw)
- Firewall configuration

### 3. Customer Completes Setup

Send the customer these instructions:

```bash
# SSH into the VPS
ssh YOUR_SSH_USER@YOUR_VPS_IP

# Run the interactive onboarding wizard
openclaw onboard

# Follow the prompts to:
# - Choose auth method (API key or setup-token)
# - Enter credentials
# - Configure Telegram bot
# - Install daemon service
```

**Benefits:**
- ✅ You never touch customer credentials
- ✅ Customer has full control
- ✅ Simpler for you (just provision VPS)

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
