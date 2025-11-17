# Vault Policy: MCP Shopify (Gemini Read-Only)
# Permite solo a Gemini leer datos de Shopify (datos sensibles de negocio)

path "smarteros/mcp/shopify" {
  capabilities = ["read", "list"]
}

path "smarteros/mcp/shopify/*" {
  capabilities = ["read", "list"]
}

# Copilot NO tiene acceso directo, solo puede leer schemas públicos
# Si Copilot necesita tipos, Gemini los provee via execution plan
