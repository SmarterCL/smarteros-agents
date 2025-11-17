# Vault Policy: MCP Admin (Full Access)
# Permite acceso completo a todos los MCPs para administración

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# All MCP Providers (Full Access)
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

path "smarteros/mcp/*" {
  capabilities = ["create", "read", "update", "delete", "list"]
}

path "smarteros/mcp/+/*" {
  capabilities = ["create", "read", "update", "delete", "list"]
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# SSH & Infrastructure
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

path "smarteros/ssh/*" {
  capabilities = ["create", "read", "update", "delete", "list"]
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# Agent States (Read-Only for debugging)
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

path "smarteros/agents/*" {
  capabilities = ["read", "list"]
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# State & Metadata
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

path "smarteros/state/*" {
  capabilities = ["create", "read", "update", "delete", "list"]
}

path "smarteros/metadata/*" {
  capabilities = ["create", "read", "update", "delete", "list"]
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# Logs (Read-Only)
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

path "smarteros/logs/*" {
  capabilities = ["read", "list"]
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# System Info
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

path "sys/mounts" {
  capabilities = ["read"]
}

path "sys/policies/acl" {
  capabilities = ["list"]
}

path "sys/policies/acl/*" {
  capabilities = ["read"]
}
