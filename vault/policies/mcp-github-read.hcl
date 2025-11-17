# Vault Policy: MCP GitHub (Read-Only)
# Permite leer secretos de GitHub para todos los agentes

path "smarteros/mcp/github" {
  capabilities = ["read", "list"]
}

path "smarteros/mcp/github/*" {
  capabilities = ["read", "list"]
}

# Metadata (opcional)
path "smarteros/metadata/mcp/github" {
  capabilities = ["read"]
}
