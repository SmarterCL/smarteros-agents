# Vault Policy: MCP Slack (Read-Write)
# Permite leer credenciales y escribir logs de notificaciones

path "smarteros/mcp/slack" {
  capabilities = ["read", "list"]
}

path "smarteros/mcp/slack/*" {
  capabilities = ["read", "list"]
}

# Logs de notificaciones enviadas
path "smarteros/logs/slack/*" {
  capabilities = ["create", "read", "update", "list"]
}

path "smarteros/metadata/mcp/slack" {
  capabilities = ["read"]
}
