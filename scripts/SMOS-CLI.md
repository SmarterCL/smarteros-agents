# SMOS CLI - SmarterOS Command Line Interface

## 🚀 Installation

```bash
# Clone repository
git clone https://github.com/SmarterCL/SmarterOS.git
cd SmarterOS

# Make executable
chmod +x smarteros-specs/scripts/smos

# Create symlink
sudo ln -s $(pwd)/smarteros-specs/scripts/smos /usr/local/bin/smos

# Initialize
smos init
```

## ⚙️ Configuration

```bash
# Set Vault token
smos config set vault.token YOUR_VAULT_TOKEN

# Set default tenant
smos config set defaults.tenant_id your-tenant

# View current config
smos config get
```

## 📋 Commands

### Services Management

```bash
# List all services
smos services list

# Check service status
smos services status n8n

# View logs
smos services logs n8n
smos services logs odoo -f  # Follow logs

# Restart service
smos services restart postgres
```

### Vault Operations

```bash
# Read secret
smos vault read smarteros/mcp/github

# Write secret
smos vault write smarteros/mcp/test api_key=abc123

# List secrets
smos vault list smarteros/mcp/
```

### Deploy Operations

```bash
# Deploy frontend to Vercel
smos deploy frontend

# Deploy backend services
smos deploy backend

# Deploy everything
smos deploy all
```

### Backup & Recovery

```bash
# Create backup
smos backup create

# List backups
smos backup list

# Restore from backup
smos backup restore 20251117_020000
```

### Tenant Management

```bash
# List tenants
smos tenants list

# Create new tenant
smos tenants create acme-corp

# Get tenant info
smos tenants info acme-corp
```

### MCP Providers

```bash
# List MCP providers
smos mcp list

# Test provider connection
smos mcp test github
smos mcp test supabase
```

### Health Check

```bash
# Run full health check
smos health
```

## 🎯 Common Workflows

### Deploy New Version

```bash
# 1. Backup current state
smos backup create

# 2. Deploy new version
smos deploy all

# 3. Check health
smos health

# 4. Monitor logs
smos services logs n8n -f
```

### Troubleshoot Service

```bash
# Check status
smos services status chatwoot

# View recent logs
smos services logs chatwoot --tail 100

# Restart if needed
smos services restart chatwoot
```

### Manage Secrets

```bash
# Add new MCP provider credentials
smos vault write smarteros/mcp/newprovider \
  api_key=xxx \
  secret=yyy

# Read to verify
smos vault read smarteros/mcp/newprovider
```

## 🔧 Environment Variables

```bash
# Vault server
export VAULT_ADDR=https://vault.smarterbot.cl

# Vault token
export VAULT_TOKEN=your_token_here

# Custom config directory
export SMOS_HOME=~/.config/smos
```

## 📚 Examples

### Setup New Environment

```bash
# Initialize
smos init

# Configure
smos config set vault.addr https://vault.smarterbot.cl
smos config set vault.token $VAULT_TOKEN
smos config set defaults.tenant_id default

# Verify
smos health
```

### Daily Operations

```bash
# Morning check
smos health

# Deploy changes
cd front/fulldaygo.smarterbot.cl
git pull
smos deploy frontend

# Check logs
smos services logs n8n --tail 50
```

### Emergency Recovery

```bash
# List backups
smos backup list

# Restore latest
smos backup restore $(smos backup list | head -1)

# Verify services
smos health
```

## 🐛 Troubleshooting

### "SMOS not initialized"

```bash
smos init
```

### "Vault token not set"

```bash
smos config set vault.token YOUR_TOKEN
# or
export VAULT_TOKEN=YOUR_TOKEN
```

### "Service not found"

```bash
# List available services
smos services list

# Use exact service name without 'smarter-' prefix
smos services status n8n  # ✓ correct
smos services status smarter-n8n  # ✗ incorrect
```

## 🔗 Integration with Other Tools

### With GitHub Actions

```yaml
- name: Deploy with SMOS
  run: |
    smos config set vault.token ${{ secrets.VAULT_TOKEN }}
    smos deploy backend
```

### With N8N Workflows

```javascript
// HTTP Request node
const smosCommand = {
  method: 'POST',
  url: 'https://n8n.smarterbot.cl/webhook/smos',
  body: {
    command: 'services restart n8n'
  }
};
```

### With Cron

```bash
# Daily backup at 2 AM
0 2 * * * /usr/local/bin/smos backup create

# Weekly health check
0 9 * * 1 /usr/local/bin/smos health | mail -s "SmarterOS Health" admin@smarterbot.cl
```

## 📄 Version

```bash
smos version
```

Current version: **1.0.0**

---

For more information: https://docs.smarteros.cl
