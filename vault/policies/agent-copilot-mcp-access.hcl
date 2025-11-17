# Vault Policy: Agent Copilot - MCP Access
# Define todos los MCPs a los que Copilot puede acceder (mínimo necesario)

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# TIER 1: Core (solo lectura de código)
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

path "smarteros/mcp/github" {
  capabilities = ["read", "list"]
}

path "smarteros/mcp/supabase" {
  capabilities = ["read", "list"]
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# TIER 2: Business (solo schemas)
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

path "smarteros/mcp/shopify" {
  capabilities = ["read"]
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# TIER 3: AI (solo docs)
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

# Context7 es público, no necesita Vault
# path "smarteros/mcp/context7" {
#   capabilities = ["read"]
# }

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# Agent State & Memory
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

path "smarteros/agents/copilot-*" {
  capabilities = ["create", "read", "update", "delete", "list"]
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# Metadata & Audit
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

path "smarteros/metadata/mcp/github" {
  capabilities = ["read"]
}

path "smarteros/metadata/mcp/supabase" {
  capabilities = ["read"]
}

path "smarteros/logs/copilot/*" {
  capabilities = ["create", "read", "list"]
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# Restrictions (explicit deny)
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

# Copilot NO puede acceder a:
# - Datos de negocio (shopify orders, metabase, odoo)
# - Secretos de comunicación (slack, twilio, whatsapp)
# - Infraestructura (cloudflare, aws, ssh keys)
# - APIs de AI (openai, anthropic, google) - solo Gemini

# Nota: Vault policy es whitelist por defecto, 
# pero esto documenta las restricciones explícitas
