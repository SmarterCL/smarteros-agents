# Vault Policy: Agent Gemini - MCP Access
# Define todos los MCPs a los que Gemini puede acceder

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# TIER 1: Core
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

path "smarteros/mcp/github" {
  capabilities = ["read", "list"]
}

path "smarteros/mcp/supabase" {
  capabilities = ["read", "list"]
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# TIER 2: Business
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

path "smarteros/mcp/shopify" {
  capabilities = ["read", "list"]
}

path "smarteros/mcp/metabase" {
  capabilities = ["read", "list"]
}

path "smarteros/mcp/odoo" {
  capabilities = ["read", "list"]
}

path "smarteros/mcp/n8n" {
  capabilities = ["read", "list"]
}

path "smarteros/mcp/stripe" {
  capabilities = ["read", "list"]
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# TIER 3: AI
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

path "smarteros/mcp/openai" {
  capabilities = ["read", "list"]
}

path "smarteros/mcp/anthropic" {
  capabilities = ["read", "list"]
}

path "smarteros/mcp/google" {
  capabilities = ["read", "list"]
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# TIER 4: Communication
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

path "smarteros/mcp/slack" {
  capabilities = ["read", "list"]
}

path "smarteros/mcp/twilio" {
  capabilities = ["read", "list"]
}

path "smarteros/mcp/whatsapp" {
  capabilities = ["read", "list"]
}

path "smarteros/mcp/mailgun" {
  capabilities = ["read", "list"]
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# TIER 5: DevOps (read-only, Gemini no ejecuta)
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

path "smarteros/mcp/linear" {
  capabilities = ["read", "list"]
}

path "smarteros/mcp/notion" {
  capabilities = ["read", "list"]
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# Agent State & Memory
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

path "smarteros/agents/gemini-*" {
  capabilities = ["create", "read", "update", "delete", "list"]
}

path "smarteros/state/*" {
  capabilities = ["create", "read", "update", "list"]
}

# Read-only access to SSH keys (for health checks)
path "smarteros/ssh/read-only" {
  capabilities = ["read"]
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# Metadata & Audit
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

path "smarteros/metadata/mcp/*" {
  capabilities = ["read"]
}

path "smarteros/logs/gemini/*" {
  capabilities = ["create", "read", "list"]
}
