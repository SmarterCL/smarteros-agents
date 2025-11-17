# Vault Policy: MCP Hostinger (Read-Only)
# Permite leer secretos de Hostinger API para agentes autorizados
# 
# Agentes con acceso:
# - executor-codex (primary) - Todas las operaciones de infra
# - director-gemini (secondary) - Solo lectura para queries
# - ci (automation) - Solo lectura para monitoring

# Hostinger API MCP Secrets
path "smarteros/mcp/hostinger" {
  capabilities = ["read", "list"]
}

path "smarteros/mcp/hostinger/*" {
  capabilities = ["read", "list"]
}

# Metadata (opcional)
path "smarteros/metadata/mcp/hostinger" {
  capabilities = ["read"]
}

# IMPORTANTE: Hostinger tiene DOS métodos de acceso
# 
# 1. API MCP (esta policy) - smarteros/mcp/hostinger
#    - api_token (Bearer)
#    - endpoint
#    Uso: VPS management, domains, backups, firewall
# 
# 2. SSH Direct (policy separada) - smarteros/ssh/deploy  
#    - private_key, public_key, host, user
#    Uso: rsync, systemctl, logs
# 
# Esta policy solo cubre el API MCP.
# Para SSH directo, usar ssh-deploy-read.hcl
