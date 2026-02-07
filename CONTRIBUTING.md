# Contributing to OpenClaw VPS Deploy

Thanks for your interest in contributing!

---

## How to Contribute

### Reporting Issues

- Search existing issues first
- Include OS, VPS provider, error messages
- Steps to reproduce
- Expected vs actual behavior

### Suggesting Features

- Open an issue with `[Feature Request]` in title
- Describe the use case
- Explain why it would be useful

### Submitting Code

1. **Fork the repo**
2. **Create a branch**: `git checkout -b feature/my-feature`
3. **Make changes**
4. **Test on a clean VPS** (don't submit untested code)
5. **Commit**: `git commit -m "Add: my feature"`
6. **Push**: `git push origin feature/my-feature`
7. **Open a PR**

---

## Testing

**Before submitting a PR, test on a fresh VPS:**

```bash
# Spin up test VPS (Hetzner, DigitalOcean, etc.)
# Run your modified deploy script
./deploy.sh --host <test-ip> --telegram-token <token> --api-key <key>

# Verify:
# 1. Script completes without errors
# 2. Gateway starts successfully  
# 3. Telegram bot responds
# 4. Logs look clean
```

**Destroy test VPS after testing** to avoid unnecessary costs.

---

## Code Style

- **Shell scripts**: Follow existing style (2-space indent, clear comments)
- **Markdown**: Use headings, code blocks, clear structure
- **Comments**: Explain *why*, not *what*

---

## Commit Messages

Use clear, descriptive commit messages:

**Good:**
- `Fix: SSH connection timeout handling`
- `Add: Support for custom Docker image`
- `Docs: Clarify Telegram bot setup steps`

**Bad:**
- `fix stuff`
- `update`
- `changes`

---

## Pull Request Guidelines

- One feature/fix per PR
- Update README/docs if needed
- Test on clean VPS before submitting
- Describe what changed and why
- Link related issues

---

## Questions?

- Open an issue for questions
- Join [OpenClaw Discord](https://discord.com/invite/clawd)
- Tag maintainers if urgent

---

Thanks for making this better! 🙏
