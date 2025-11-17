# Vault Policy: Agent Codex - MCP Access
# Define todos los MCPs a los que Codex puede acceder (operaciones + infra)

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# TIER 0: Infrastructure (NUEVO - full access)
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

# Hostinger API MCP - Infrastructure Control
path "smarteros/mcp/hostinger" {
  capabilities = ["read", "list"]
}

path "smarteros/mcp/hostinger/*" {
  capabilities = ["read", "list"]
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# TIER 1: Core (full access)
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

path "smarteros/mcp/github" {
  capabilities = ["read", "list"]
}

path "smarteros/mcp/docker" {
  capabilities = ["read", "list"]
}

# SSH keys para deploy directo (complementa Hostinger API)
path "smarteros/ssh/*" {
  capabilities = ["read", "list"]
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# TIER 2: Business (limited)
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

path "smarteros/mcp/n8n" {
  capabilities = ["read", "list"]
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# TIER 4: Communication (notifications only)
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

path "smarteros/mcp/slack" {
  capabilities = ["read", "list"]
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# TIER 5: DevOps (full access)
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

path "smarteros/mcp/cloudflare" {
  capabilities = ["read", "list"]
}

path "smarteros/mcp/aws" {
  capabilities = ["read", "list"]
}

# Caddy usa SSH keys ya permitidas arriba

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# Agent State & Memory
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

path "smarteros/agents/codex-*" {
  capabilities = ["create", "read", "update", "delete", "list"]
}

path "smarteros/state/*" {
  capabilities = ["create", "read", "update", "list"]
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# Execution Reports
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

path "smarteros/agents/reports/*" {
  capabilities = ["create", "read", "update", "list"]
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# Metadata & Audit
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

path "smarteros/metadata/mcp/*" {
  capabilities = ["read"]
}

path "smarteros/logs/codex/*" {
  capabilities = ["create", "read", "list"]
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# Restrictions (explicit deny)
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

# Codex NO puede acceder a:
# - Datos de negocio sensibles (shopify, metabase, odoo, stripe)
# - APIs de AI (openai, anthropic, google)
# - Comunicación directa con clientes (twilio, whatsapp)
# Solo puede enviar notificaciones internas (slack)
