# Vault Policy: MCP Supabase (Read-Only)
# Permite leer credenciales de Supabase para Gemini y Copilot

path "smarteros/mcp/supabase" {
  capabilities = ["read", "list"]
}

path "smarteros/mcp/supabase/*" {
  capabilities = ["read", "list"]
}

path "smarteros/metadata/mcp/supabase" {
  capabilities = ["read"]
}
