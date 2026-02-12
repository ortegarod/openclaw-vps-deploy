# OpenClaw VPS Deployment

**Automated OpenClaw deployment to any Ubuntu VPS.**

Deploy OpenClaw in ~10 minutes using the official installer. Two deployment modes:

1. **Configured Deployment**: OpenClaw + Telegram channel + auth configured, bot ready to use
2. **Install Only**: Just install OpenClaw, configure interactively later via `openclaw onboard`

**Uses:** [Official OpenClaw installer](https://docs.openclaw.ai/install) + [Onboarding wizard](https://docs.openclaw.ai/reference/wizard)

---

## Prerequisites

**For all deployments:**
- VPS - Ubuntu 24.04 server from any provider
- SSH access - SSH key (recommended) or password

**For configured deployments:**
- Telegram bot token - From @BotFather
- User's Telegram ID - From @userinfobot
- Anthropic API key or Claude setup-token

---

## Quick Start

### Configured Deployment

Provide credentials during deployment. Bot will be ready to message immediately.

#### 1. Create a VPS

**Recommended providers:**
- [Hetzner Cloud](https://www.hetzner.com/cloud)
- [OVH](https://www.ovhcloud.com/)
- [DigitalOcean](https://www.digitalocean.com/)

**Specs:**
- OS: Ubuntu 24.04
- RAM: 4GB minimum
- Storage: 40GB+

#### 2. Verify SSH Access

**Before running the deployment script**, connect to your VPS and verify access:

```bash
ssh YOUR_SSH_USER@YOUR_VPS_IP
```

**First-time connection checklist:**
- Accept the host key fingerprint when prompted
- Change the default password if required by your provider
- Verify you can execute commands (e.g., `sudo apt update`)

**Recommended: Set up SSH key authentication**

This prevents password prompts during deployment:

```bash
# On your local machine
ssh-copy-id YOUR_SSH_USER@YOUR_VPS_IP
```

Or manually:
```bash
cat ~/.ssh/id_rsa.pub | ssh YOUR_SSH_USER@YOUR_VPS_IP "mkdir -p ~/.ssh && cat >> ~/.ssh/authorized_keys"
```

**Verify passwordless login:**
```bash
ssh YOUR_SSH_USER@YOUR_VPS_IP
# Should connect without password prompt
```

Once you can SSH in without issues, proceed to the next step.

#### 3. Create a Telegram Bot

Message [@BotFather](https://t.me/botfather) on Telegram:

```
/newbot
[Follow the prompts]
```

Save the token (format: `123456789:ABCdefGHIjklMNOpqrsTUVwxyz`)

#### 4. Get User's Telegram ID

Have the user message [@userinfobot](https://t.me/userinfobot) on Telegram.

It will reply with their user ID (format: `987654321`)

**Note:** This pre-authorizes the user so they can message the bot immediately.

#### 5. Get Authentication

Go to [Anthropic Console](https://console.anthropic.com/):

1. Sign up or log in
2. Go to **API Keys** section
3. Click **Create Key**
4. Save the key (format: `sk-ant-api03-...`)

**Or** use Claude subscription setup-token: `claude setup-token`

#### 6. Clone the Deployment Script

```bash
git clone https://github.com/ortegarod/openclaw-vps-deploy.git
cd openclaw-vps-deploy
```

#### 7. Run the Deploy Script

**With API Key:**

```bash
./deploy.sh \
  --host YOUR_VPS_IP \
  --user YOUR_SSH_USER \
  --telegram-token "YOUR_TELEGRAM_TOKEN" \
  --telegram-user-id USER_TELEGRAM_ID \
  --api-key "YOUR_CLAUDE_API_KEY"
```

**Or with Claude subscription setup-token:**

```bash
./deploy.sh \
  --host YOUR_VPS_IP \
  --user YOUR_SSH_USER \
  --telegram-token "YOUR_TELEGRAM_TOKEN" \
  --telegram-user-id USER_TELEGRAM_ID \
  --token "YOUR_SETUP_TOKEN"
```

**Fresh installation (wipe existing workspace):**

Add `--clean` to remove existing identity/workspace files:

```bash
./deploy.sh \
  --host YOUR_VPS_IP \
  --user YOUR_SSH_USER \
  --telegram-token "YOUR_TELEGRAM_TOKEN" \
  --telegram-user-id USER_TELEGRAM_ID \
  --token "YOUR_SETUP_TOKEN" \
  --clean
```

**Use `--clean` when:**
- Redeploying to an existing VPS
- Want a fresh start
- Previous bot identity should be removed

**What gets configured:**
- OpenClaw CLI + dependencies
- Authentication (API key or setup-token)
- Telegram channel (bot token + pre-authorized user)
- Gateway daemon (systemd service)
- Firewall (SSH + Gateway port)

Replace:
- `YOUR_VPS_IP` with VPS IP address (e.g., `203.0.113.10`)
- `YOUR_SSH_USER` with SSH username (e.g., `ubuntu`, `root`)
- `YOUR_TELEGRAM_TOKEN` with bot token from step 3
- `USER_TELEGRAM_ID` with user's Telegram ID from step 4 (e.g., `987654321`)
- `YOUR_CLAUDE_API_KEY` with API key from step 5 **OR**
- `YOUR_SETUP_TOKEN` with Claude setup-token

**Important SSH notes:**
- Use the **IP address**, not hostname (unless DNS is configured)
- Specify `--user` to match your SSH config (default is `root`)
- Script uses your existing SSH keys automatically
- If VS Code or SSH access works, use the same IP and user

#### 8. Done!

**Bot is ready!** User can message on Telegram immediately (pre-authorized, no pairing needed).

---

### Install-Only Deployment

Install OpenClaw without credentials. User configures via interactive wizard.

#### 1. Create a VPS

Same as configured deployment (see above).

#### 2. Run the Deploy Script

```bash
git clone https://github.com/ortegarod/openclaw-vps-deploy.git
cd openclaw-vps-deploy

./deploy.sh \
  --host YOUR_VPS_IP \
  --user YOUR_SSH_USER
```

**That's it!** Installs:
- OpenClaw CLI
- System dependencies (curl, git, ufw)
- Firewall configuration

#### 3. Complete Setup

SSH in and run the interactive wizard:

```bash
ssh YOUR_SSH_USER@YOUR_VPS_IP
openclaw onboard

# Follow prompts:
# - Choose auth method (API key or setup-token)
# - Enter credentials
# - Configure Telegram bot
# - Install daemon service
```

---

## What Gets Installed

### Both Modes
1. **OpenClaw CLI** via `curl -fsSL https://openclaw.ai/install.sh | bash`
2. **System packages** curl, git, ufw (firewall)
3. **Firewall rules** SSH (22), Gateway (18789)

### Configured Mode Also Includes
4. **Onboarding** via `openclaw onboard --non-interactive`
5. **Telegram channel** pre-authorized for specified user ID
6. **Gateway daemon** systemd service for auto-restart

### Directory Structure

```
~/.openclaw/
├── bin/openclaw            # OpenClaw CLI
├── openclaw.json           # Configuration
├── workspace/              # Agent workspace
│   ├── AGENTS.md
│   ├── IDENTITY.md
│   ├── SOUL.md
│   └── ...
├── agents/main/sessions/   # Session history
└── credentials/            # Channel credentials
```

---

## Post-Deployment

### Customize the Agent

SSH into VPS and edit workspace files:

```bash
ssh YOUR_USER@YOUR_IP
nano ~/.openclaw/workspace/IDENTITY.md
nano ~/.openclaw/workspace/SOUL.md
```

Restart to apply:
```bash
openclaw gateway restart
```

### Check Status

```bash
ssh YOUR_USER@YOUR_IP
openclaw status
```

### View Logs

```bash
openclaw logs --follow
```

### Restart Gateway

```bash
openclaw gateway restart
```

### Update OpenClaw

```bash
# Re-run installer
curl -fsSL https://openclaw.ai/install.sh | bash
openclaw gateway restart
```

---

## Troubleshooting

### SSH Connection Fails

If you see "Permission denied" or "Cannot connect":

1. **Check SSH config** (`~/.ssh/config`) if using VS Code or similar tools
2. **Use same IP and user** that works in your SSH client:
   ```bash
   ./deploy.sh --host YOUR_IP --user YOUR_USER
   ```
3. **Test SSH manually first:**
   ```bash
   ssh YOUR_USER@YOUR_IP
   ```

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

## Security

**Deployment includes:**
- UFW firewall (SSH + Gateway port)
- Systemd service isolation
- DM pairing or allowlist (not open by default)

**Additional recommendations:**
- Use SSH keys (not passwords)
- Keep VPS updated: `sudo apt update && sudo apt upgrade`
- Review [OpenClaw security docs](https://docs.openclaw.ai/security)
- Run security audit: `openclaw security audit`

---

## Documentation

- [OpenClaw Docs](https://docs.openclaw.ai)
- [Installation](https://docs.openclaw.ai/install)
- [Onboarding Wizard](https://docs.openclaw.ai/start/wizard)
- [Channels](https://docs.openclaw.ai/channels)
- [Security](https://docs.openclaw.ai/security)

---

## Contributing

Contributions welcome! Test on a clean Ubuntu 24.04 VPS before submitting PR.

---

## License

MIT License - See [LICENSE](LICENSE)

---

## Credits

Built using the [official OpenClaw installer](https://openclaw.ai/install.sh).

**Questions?** [OpenClaw Discord](https://discord.com/invite/clawd)
