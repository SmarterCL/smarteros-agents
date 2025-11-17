# Vault Policy: CI Read-Only
# Para GitHub Actions y otros CI/CD (solo lectura de secretos necesarios)

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# SSH Keys for Deployment
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

path "smarteros/ssh/deploy" {
  capabilities = ["read"]
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# Application Secrets
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

path "smarteros/app/*" {
  capabilities = ["read"]
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# MCP Providers (Read-Only)
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

path "smarteros/mcp/github" {
  capabilities = ["read"]
}

path "smarteros/mcp/slack" {
  capabilities = ["read"]
}

path "smarteros/mcp/supabase" {
  capabilities = ["read"]
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# CI State (Write for caching)
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

path "smarteros/ci/*" {
  capabilities = ["create", "read", "update", "list"]
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# Logs (Write for audit)
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

path "smarteros/logs/ci/*" {
  capabilities = ["create", "read", "list"]
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# Restrictions
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

# CI NO puede:
# - Modificar secretos (create, update, delete en smarteros/mcp/*)
# - Acceder a datos de negocio (shopify, metabase, odoo, stripe)
# - Leer states de agentes (smarteros/agents/*)
# - Modificar políticas (sys/policies/*)
