# Deployment Examples

Common deployment scenarios.

---

## Configured Deployment (Full Setup)

Bot ready to message immediately.

### Basic Setup

```bash
./deploy.sh \
  --host 203.0.113.45 \
  --user ubuntu \
  --telegram-token "123456789:ABCdefGHIjklMNOpqrsTUVwxyz" \
  --telegram-user-id 987654321 \
  --api-key "sk-ant-api03-..."
```

### With Claude Subscription

```bash
./deploy.sh \
  --host 203.0.113.45 \
  --user ubuntu \
  --telegram-token "123456:ABC..." \
  --telegram-user-id 987654321 \
  --token "YOUR_SETUP_TOKEN"
```

### Fresh Installation (Wipe Existing)

```bash
./deploy.sh \
  --host 203.0.113.45 \
  --user ubuntu \
  --telegram-token "123456:ABC..." \
  --telegram-user-id 987654321 \
  --api-key "sk-ant-..." \
  --clean
```

### Custom Agent Name

```bash
./deploy.sh \
  --host 203.0.113.45 \
  --user ubuntu \
  --telegram-token "123456:ABC..." \
  --telegram-user-id 987654321 \
  --api-key "sk-ant-..." \
  --name "research-assistant"
```

### Different Model

```bash
./deploy.sh \
  --host 203.0.113.45 \
  --user ubuntu \
  --telegram-token "123456:ABC..." \
  --telegram-user-id 987654321 \
  --api-key "sk-ant-..." \
  --model "anthropic/claude-opus-4-6"
```

---

## Install-Only Deployment

Just install OpenClaw, configure later.

### Basic Install

```bash
./deploy.sh \
  --host 203.0.113.45 \
  --user ubuntu
```

Then SSH in and configure:

```bash
ssh ubuntu@203.0.113.45
openclaw onboard
```

---

## Post-Deployment

### Check Status

```bash
ssh ubuntu@203.0.113.45 'openclaw status'
```

### View Logs

```bash
ssh ubuntu@203.0.113.45 'openclaw logs --follow'
```

### Restart Gateway

```bash
ssh ubuntu@203.0.113.45 'openclaw gateway restart'
```

### Customize Agent

```bash
ssh ubuntu@203.0.113.45

# Edit identity
nano ~/.openclaw/workspace/IDENTITY.md

# Edit personality
nano ~/.openclaw/workspace/SOUL.md

# Restart
openclaw gateway restart
```

---

## Update OpenClaw

```bash
ssh ubuntu@203.0.113.45

# Re-run installer
curl -fsSL https://openclaw.ai/install.sh | bash

# Restart
openclaw gateway restart
```

---

## Backup & Restore

### Backup

```bash
# From local machine
rsync -avz ubuntu@203.0.113.45:~/.openclaw/ ./backup-$(date +%Y%m%d)/
```

### Restore

```bash
# To new VPS
rsync -avz ./backup-20260207/ ubuntu@203.0.113.46:~/.openclaw/
ssh ubuntu@203.0.113.46 'openclaw gateway restart'
```

---

## Troubleshooting

### Test Telegram Connection

Send message to bot, then check logs:

```bash
ssh ubuntu@203.0.113.45 'openclaw logs --tail 50'
```

### Check Telegram Config

```bash
ssh ubuntu@203.0.113.45 'openclaw channels list'
```

### Gateway Not Running

```bash
ssh ubuntu@203.0.113.45 'openclaw gateway start'
```

---

More examples? Open an issue or PR!
