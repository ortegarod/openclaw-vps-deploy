# Deployment Examples

Common deployment scenarios for OpenClaw on VPS.

---

## Basic Deployment

**Minimal setup with defaults:**

```bash
./deploy.sh \
  --host 203.0.113.45 \
  --telegram-token "123456789:ABCdefGHIjklMNOpqrsTUVwxyz" \
  --api-key "sk-ant-api03-..."
```

This creates:
- Agent named "openclaw-agent"
- Using claude-sonnet-4-5
- SSH as root

---

## Custom Agent Name

**Deploy with a specific name:**

```bash
./deploy.sh \
  --host 203.0.113.45 \
  --name "research-assistant" \
  --telegram-token "123456:ABC..." \
  --api-key "sk-ant-..."
```

---

## Different Model

**Use Claude Opus instead of Sonnet:**

```bash
./deploy.sh \
  --host 203.0.113.45 \
  --model "anthropic/claude-opus-4-6" \
  --telegram-token "123456:ABC..." \
  --api-key "sk-ant-..."
```

**Use OpenRouter with a different model:**

```bash
./deploy.sh \
  --host 203.0.113.45 \
  --model "openrouter/anthropic/claude-4.5-sonnet" \
  --telegram-token "123456:ABC..." \
  --api-key "sk-or-v1-..."
```

---

## Non-Root User

**Deploy using a non-root SSH user:**

```bash
./deploy.sh \
  --host 203.0.113.45 \
  --user ubuntu \
  --telegram-token "123456:ABC..." \
  --api-key "sk-ant-..."
```

*Note: User needs sudo access for installation*

---

## Multiple Agents

**Deploy multiple agents on separate VPS instances:**

```bash
# Personal agent
./deploy.sh \
  --host 203.0.113.45 \
  --name "personal-assistant" \
  --telegram-token "111111:AAA..." \
  --api-key "sk-ant-..."

# Work agent
./deploy.sh \
  --host 203.0.113.46 \
  --name "work-assistant" \
  --telegram-token "222222:BBB..." \
  --api-key "sk-ant-..."

# Research agent
./deploy.sh \
  --host 203.0.113.47 \
  --name "research-bot" \
  --model "anthropic/claude-opus-4-6" \
  --telegram-token "333333:CCC..." \
  --api-key "sk-ant-..."
```

---

## Using OpenRouter

**Deploy with OpenRouter instead of direct Anthropic:**

```bash
./deploy.sh \
  --host 203.0.113.45 \
  --model "openrouter/anthropic/claude-4.5-sonnet" \
  --telegram-token "123456:ABC..." \
  --api-key "sk-or-v1-your-openrouter-key"
```

---

## Post-Deployment Customization

After deployment, SSH in and customize:

```bash
ssh root@203.0.113.45

# Edit agent identity
nano /root/.openclaw/workspace/IDENTITY.md

# Edit personality
nano /root/.openclaw/workspace/SOUL.md

# Add user context
nano /root/.openclaw/workspace/USER.md

# Restart to apply
systemctl restart openclaw
```

---

## Updating OpenClaw

**Get latest version:**

```bash
ssh root@203.0.113.45

# Re-run installer
curl -fsSL https://openclaw.ai/install.sh | bash

# Restart gateway
systemctl restart openclaw
```

---

## Backup & Restore

### Backup

```bash
# From your local machine
rsync -avz root@203.0.113.45:/root/.openclaw/ ./backup-$(date +%Y%m%d)/
```

### Restore

```bash
# To a new VPS
rsync -avz ./backup-20260207/ root@203.0.113.46:/root/.openclaw/

# Restart gateway
ssh root@203.0.113.46 'systemctl restart openclaw'
```

---

## Troubleshooting Examples

### Check if gateway is running

```bash
ssh root@203.0.113.45 'systemctl status openclaw'
```

### View logs

```bash
ssh root@203.0.113.45 'journalctl -u openclaw -f'
```

### Restart gateway

```bash
ssh root@203.0.113.45 'systemctl restart openclaw'
```

### Test Telegram connection

Send a message to your bot via Telegram and check logs:

```bash
ssh root@203.0.113.45 'journalctl -u openclaw --tail=50'
```

---

## Advanced: Custom Config

Deploy with defaults then edit config manually:

```bash
# Deploy
./deploy.sh --host 203.0.113.45 --telegram-token "..." --api-key "..."

# SSH in
ssh root@203.0.113.45

# Edit config
nano /root/.openclaw/config.json

# Restart
systemctl restart openclaw
```

Example custom config sections:

```json
{
  "agents": {
    "defaults": {
      "model": {
        "primary": "anthropic/claude-opus-4-6",
        "fallback": "anthropic/claude-sonnet-4-5"
      },
      "thinking": "low",
      "sandbox": {
        "mode": "non-main"
      }
    }
  }
}
```

---

More examples? Open an issue or PR!
