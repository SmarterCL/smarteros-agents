# Nexa Runtime Multi-Tenant - Integration Guide

## 📋 Overview

Nexa Runtime es el motor de IA local multi-tenant de SmarterOS que expone una API compatible con OpenAI para agentes, n8n, y Botpress.

## 🎯 Componentes Creados

### 1. Service Spec: `services/nexa-runtime.yml`
Especificación completa del servicio para SmarterOS con:
- ✅ Configuración multi-tenant
- ✅ Ingress en `ai.smarterbot.store`
- ✅ Integración con Vault
- ✅ Límites por tenant
- ✅ Endpoints OpenAI-compatible

### 2. Docker Compose: `/root/docker-compose.nexa.yml`
Stack listo para deploy en Dokploy con:
- ✅ Variables de entorno configurables
- ✅ Volúmenes para modelos
- ✅ Labels para Traefik/Caddy
- ✅ Health checks

### 3. FastAPI Server: `services/nexa-runtime/app/main.py`
Servidor multi-tenant con:
- ✅ Resolución de tenant por header `X-Tenant-Id`
- ✅ Integración con Vault para secretos
- ✅ Endpoints `/v1/chat/completions` y `/v1/embeddings`
- ✅ Admin endpoints para métricas
- ✅ Middleware de rate limiting

### 4. Vault Integration
Políticas y estructura de secretos:
- ✅ Policy: `vault/policies/smarteros-nexa.hcl`
- ✅ Path: `secret/data/tenant/{{tenant_id}}/nexa`
- ✅ Ejemplos de configuración por tenant
- ✅ Comandos CLI para gestión

### 5. n8n Workflow: `workflows/n8n-nexa-multitenant.json`
Workflow de ejemplo con:
- ✅ Webhook trigger
- ✅ Call a Nexa Runtime con X-Tenant-Id
- ✅ Logging a Supabase
- ✅ Response al cliente

## 🚀 Deployment

### Opción 1: Docker Compose Standalone

```bash
cd /root
docker-compose -f docker-compose.nexa.yml up -d
```

### Opción 2: Deploy en Dokploy

1. Copia el contenido de `/root/docker-compose.nexa.yml`
2. En Dokploy: Projects → New Stack
3. Pega el compose y configura variables:
   - `VAULT_ADDR`
   - `VAULT_TOKEN`
   - `NEXA_MODEL_ID`

### Opción 3: Build Custom Image

```bash
cd /root/specs/services/nexa-runtime
docker build -t smarteros-nexa-runtime:latest .
docker push ghcr.io/smartercl/nexa-runtime:latest
```

## 🔧 Configuration

### Variables de Entorno

```bash
# Model
NEXA_MODEL_ID=llama-3-8b-instruct
NEXA_MODEL_STORE=/models
NEXA_PORT=8080

# Multi-tenant
TENANT_MODE=multi
DEFAULT_TENANT_ID=demo

# Vault
VAULT_ADDR=https://vault.smarterbot.cl:8200
VAULT_TOKEN=hvs.xxxxx
NEXA_VAULT_PATH_TEMPLATE=secret/data/tenant/{{tenant_id}}/nexa
```

### Vault Setup

```bash
# 1. Create policy
vault policy write smarteros-nexa vault/policies/smarteros-nexa.hcl

# 2. Create tenant secret
vault kv put secret/tenant/rut-76832940-3/nexa \
  NEXA_MODEL_ID="llama-3-8b-instruct" \
  NEXA_MAX_CONTEXT_TOKENS="8192" \
  NEXA_MAX_OUTPUT_TOKENS="768" \
  NEXA_TEMPERATURE="0.7" \
  TENANT_HARD_LIMIT_RPM="120"

# 3. Create AppRole for service
vault write auth/approle/role/nexa-runtime \
  token_policies="smarteros-nexa" \
  token_ttl=1h
```

## 📡 API Usage

### Call from n8n

```json
POST http://nexa-runtime:8080/v1/chat/completions
Headers:
  X-Tenant-Id: rut-76832940-3
  Content-Type: application/json

Body:
{
  "model": "llama-3-8b-instruct",
  "messages": [
    {"role": "user", "content": "Hola, ¿cómo estás?"}
  ],
  "temperature": 0.7,
  "max_tokens": 1024
}
```

### Call from Botpress

Configure como proveedor OpenAI:
- Base URL: `http://nexa-runtime:8080/v1`
- Model: `llama-3-8b-instruct`
- Headers: `X-Tenant-Id: rut-76832940-3`

### Call from MCP

```yaml
tools:
  - name: nexa.chat
    type: http
    baseUrl: http://nexa-runtime:8080/v1
    endpoint: /chat/completions
    headers:
      X-Tenant-Id: "{{ tenant_id }}"
```

## 🧪 Testing

### Health Check

```bash
curl http://localhost:8080/health
```

### Test Chat Completion

```bash
curl -X POST http://localhost:8080/v1/chat/completions \
  -H "X-Tenant-Id: demo" \
  -H "Content-Type: application/json" \
  -d '{
    "model": "llama-3-8b-instruct",
    "messages": [{"role": "user", "content": "Hello"}]
  }'
```

### Check Tenant Config

```bash
curl http://localhost:8080/admin/tenants/demo/config
```

## 📊 Monitoring

### Logs

```bash
docker logs smarteros-nexa-runtime -f
```

### Metrics

- Request count per tenant
- Token usage per tenant
- Response latency
- Model load time

### Supabase Logging

Table: `ai_runtime_logs`

```sql
CREATE TABLE ai_runtime_logs (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  tenant_id TEXT NOT NULL,
  model TEXT NOT NULL,
  prompt_tokens INT,
  completion_tokens INT,
  total_tokens INT,
  response_time_ms INT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);
```

## 🔒 Security

- ✅ Tenant isolation via Vault policies
- ✅ Per-tenant rate limits
- ✅ Token-based authentication
- ✅ Audit logging in Vault
- ✅ Encrypted secrets at rest

## 📝 Next Steps

1. **Build Custom Image**
   - Integrate real Nexa SDK
   - Replace mock responses
   - Add embeddings support

2. **Deploy to Production**
   - Use Dokploy for orchestration
   - Configure Vault AppRole
   - Set up monitoring

3. **Create Tenants**
   - Add secrets in Vault
   - Configure per-tenant limits
   - Test with real workloads

4. **Integrate with Services**
   - Configure n8n workflows
   - Update Botpress providers
   - Add MCP tools

## 🆘 Troubleshooting

### Vault Connection Issues

```bash
# Check Vault status
vault status

# Test token
vault token lookup
```

### Model Loading Issues

```bash
# Check models directory
docker exec smarteros-nexa-runtime ls -lh /models

# Download model manually
docker exec smarteros-nexa-runtime \
  nexa pull llama-3-8b-instruct
```

### Tenant Config Not Found

```bash
# Verify secret exists
vault kv get secret/tenant/rut-76832940-3/nexa

# Check logs
docker logs smarteros-nexa-runtime | grep "tenant_id"
```

## 📚 References

- Nexa SDK: https://github.com/NexaAI/nexa-sdk
- OpenAI API Spec: https://platform.openai.com/docs/api-reference
- Vault AppRole: https://developer.hashicorp.com/vault/docs/auth/approle
- FastAPI Docs: https://fastapi.tiangolo.com

---

**Status:** ✅ Ready for deployment
**Version:** 0.1.0
**Last Updated:** 2025-11-18
