# 🔐 Vault Policies - MCP & Agent Isolation

Políticas de Vault para aislamiento granular de MCP providers por agente.

## 📋 Estructura

```
smarteros-specs/vault/policies/
├── README.md
│
├── mcp-github-read.hcl              # Provider-specific
├── mcp-supabase-read.hcl
├── mcp-shopify-gemini-read.hcl
├── mcp-slack-write.hcl
│
├── agent-gemini-mcp-access.hcl      # Agent-specific
├── agent-copilot-mcp-access.hcl
├── agent-codex-mcp-access.hcl
│
├── mcp-admin-full.hcl               # Admin
└── ci-readonly.hcl                  # CI/CD
```

## 🎯 Principios

### 1. Least Privilege

Cada agente solo accede a los MCPs necesarios para su función:

- **Gemini** (Director): 15 MCPs
  - Tier 1: github, vault, supabase
  - Tier 2: shopify, metabase, odoo, n8n, stripe
  - Tier 3: openai, anthropic, google
  - Tier 4: slack, twilio, whatsapp, mailgun
  - Tier 5: linear, notion

- **Copilot** (Writer): 4 MCPs
  - Tier 1: github, vault, supabase
  - Tier 2: shopify (solo schemas)
  - Tier 3: context7 (público)

- **Codex** (Executor): 9 MCPs
  - Tier 1: github, vault, docker, hostinger (SSH)
  - Tier 2: n8n
  - Tier 4: slack
  - Tier 5: cloudflare, aws, caddy

### 2. Read-Only por Defecto

Todos los MCPs son **read-only** en Vault (capabilities = ["read", "list"]).

Los agentes **no pueden modificar secretos**, solo leerlos.

### 3. Aislamiento de Datos Sensibles

- **Shopify orders/customers**: Solo Gemini
- **SSH keys**: Solo Codex
- **API keys de AI**: Solo Gemini
- **Tokens de comunicación externa**: Solo Gemini

### 4. Audit Completo

Todos los accesos a `smarteros/mcp/*` están auditados.

## 🚀 Uso

### Aplicar Políticas

```bash
cd ~/dev/2025/scripts

# Aplicar todas las políticas
./apply-vault-policies.sh

# Solo MCPs
./apply-vault-policies.sh --mcp-only

# Solo agentes
./apply-vault-policies.sh --agents

# Listar políticas actuales
./apply-vault-policies.sh --list
```

### Crear Roles de Agentes

```bash
# Crear roles en Vault
./apply-vault-policies.sh --roles

# Genera roles:
# - agent-gemini (policy: agent-gemini-mcp-access)
# - agent-copilot (policy: agent-copilot-mcp-access)
# - agent-codex (policy: agent-codex-mcp-access)
# - ci (policy: ci-readonly)
```

### Generar Tokens por Agente

```bash
# Generar tokens de prueba
./apply-vault-policies.sh --tokens

# Output:
# export VAULT_TOKEN_GEMINI=hvs.xxx
# export VAULT_TOKEN_COPILOT=hvs.yyy
# export VAULT_TOKEN_CODEX=hvs.zzz
```

### Verificar Acceso

```bash
# Test Gemini access
export VAULT_TOKEN=$VAULT_TOKEN_GEMINI
vault kv get smarteros/mcp/shopify    # ✅ OK
vault kv get smarteros/ssh/deploy     # ❌ Denied (no es Codex)

# Test Copilot access
export VAULT_TOKEN=$VAULT_TOKEN_COPILOT
vault kv get smarteros/mcp/github     # ✅ OK
vault kv get smarteros/mcp/shopify    # ❌ Denied (solo Gemini tiene full access)

# Test Codex access
export VAULT_TOKEN=$VAULT_TOKEN_CODEX
vault kv get smarteros/ssh/deploy     # ✅ OK
vault kv get smarteros/mcp/openai     # ❌ Denied (solo Gemini)
```

## 📊 Matriz de Acceso

| MCP Provider | Gemini | Copilot | Codex | Notas |
|--------------|--------|---------|-------|-------|
| github | ✅ | ✅ | ✅ | Todos necesitan |
| vault | ✅ | ✅ | ✅ | Auto-referencia |
| supabase | ✅ | ✅ | ❌ | Schema + queries |
| docker | ❌ | ❌ | ✅ | Solo ops |
| hostinger (SSH) | ❌ | ❌ | ✅ | Solo deploy |
| shopify | ✅ | ⚠️ | ❌ | Gemini full, Copilot schemas |
| metabase | ✅ | ❌ | ❌ | Analytics |
| odoo | ✅ | ❌ | ❌ | ERP data |
| n8n | ✅ | ❌ | ✅ | Workflows |
| stripe | ✅ | ❌ | ❌ | Payments |
| openai | ✅ | ❌ | ❌ | AI inference |
| anthropic | ✅ | ❌ | ❌ | AI inference |
| google | ✅ | ❌ | ❌ | AI inference |
| context7 | ❌ | ✅ | ❌ | Docs (público) |
| slack | ✅ | ❌ | ✅ | Notificaciones |
| twilio | ✅ | ❌ | ❌ | SMS |
| whatsapp | ✅ | ❌ | ❌ | Messaging |
| mailgun | ✅ | ❌ | ❌ | Email |
| cloudflare | ❌ | ❌ | ✅ | DNS/CDN |
| aws | ❌ | ❌ | ✅ | S3/CloudFront |
| caddy | ❌ | ❌ | ✅ | Reverse proxy |
| linear | ✅ | ❌ | ❌ | Project mgmt |
| notion | ✅ | ❌ | ❌ | Docs |

## 🔒 Políticas Detalladas

### MCP Provider Policies

Cada provider tiene su propia policy para control granular:

- `mcp-github-read.hcl`: Lectura de repos, issues, PRs
- `mcp-supabase-read.hcl`: Schema, queries, auth
- `mcp-shopify-gemini-read.hcl`: Solo Gemini accede a orders/customers
- `mcp-slack-write.hcl`: Lee credentials + escribe logs de notificaciones

### Agent Policies

Agregan todas las policies necesarias por agente:

- `agent-gemini-mcp-access.hcl`:
  - 15 MCP providers
  - Read/write en `smarteros/agents/gemini-*`
  - Read/write en `smarteros/state/*`

- `agent-copilot-mcp-access.hcl`:
  - 4 MCP providers (mínimo necesario)
  - Read/write solo en `smarteros/agents/copilot-*`
  - NO acceso a datos de negocio

- `agent-codex-mcp-access.hcl`:
  - 9 MCP providers (infra + ops)
  - Full access a SSH keys
  - Read/write en reports y state

### Admin Policies

- `mcp-admin-full.hcl`: Full access a todos los MCPs (humano admin)
- `ci-readonly.hcl`: GitHub Actions (solo SSH + deploy secrets)

## 🔄 Rotación de Secretos

Los secretos en `smarteros/mcp/*` deben rotarse cada 90 días:

```bash
# Rotar GitHub token
vault kv put smarteros/mcp/github \
  token="ghp_newtoken" \
  org="SmarterCL" \
  webhook_secret="newsecret"

# Los agentes automáticamente usan el nuevo token
# No necesitan actualización de policies
```

## 📝 Audit Log

Todos los accesos están en el audit log de Vault:

```bash
# Ver audit logs
ssh smarteros 'journalctl -u vault --since "1 hour ago" | grep "smarteros/mcp"'

# Ver accesos por agente
vault audit list
vault read sys/audit/file/log
```

## 🧪 Testing

```bash
# Test 1: Gemini puede leer Shopify
VAULT_TOKEN=$VAULT_TOKEN_GEMINI vault kv get smarteros/mcp/shopify
# Expected: Success

# Test 2: Copilot NO puede leer Shopify (full)
VAULT_TOKEN=$VAULT_TOKEN_COPILOT vault kv get smarteros/mcp/shopify
# Expected: Permission denied

# Test 3: Codex puede leer SSH keys
VAULT_TOKEN=$VAULT_TOKEN_CODEX vault kv get smarteros/ssh/deploy
# Expected: Success

# Test 4: Gemini NO puede leer SSH keys
VAULT_TOKEN=$VAULT_TOKEN_GEMINI vault kv get smarteros/ssh/deploy
# Expected: Permission denied (solo read-only path)
```

## 🚨 Troubleshooting

### Error: Permission Denied

```bash
# Ver capabilities del token actual
vault token capabilities smarteros/mcp/github

# Ver política asignada
vault token lookup

# Renovar token si expiró
vault token renew
```

### Error: Policy Not Found

```bash
# Listar policies
vault policy list

# Re-aplicar policy
./apply-vault-policies.sh
```

## 📚 Referencias

- [Vault Policies](https://developer.hashicorp.com/vault/docs/concepts/policies)
- [MCP Registry](../mcp/index.yml)
- [Agent Specs](../agents/)
- [Bootstrap Script](../../scripts/bootstrap-mcp-vault.sh)

---

**Principio fundamental**: Cada agente solo ve los secretos que necesita para su función específica. Zero Trust.
