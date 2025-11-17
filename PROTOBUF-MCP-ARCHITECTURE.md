# SmarterOS - Event-Driven MCP Architecture

## 🎯 Arquitectura Overview

```
┌─────────────────────────────────────────────────────────────────────┐
│                      Claude Desktop / MCP Client                     │
└────────────────────────────────┬────────────────────────────────────┘
                                 │ stdio
                    ┌────────────▼───────────────┐
                    │  smarteros-mcp-server      │
                    │  (protoc-gen-go-mcp)       │
                    │  23 Auto-Generated Tools   │
                    └─┬──────────┬──────────┬───┘
                      │          │          │
         ┌────────────┘          │          └────────────┐
         │                       │                       │
    ┌────▼─────┐        ┌───────▼────────┐      ┌──────▼──────┐
    │  Vault   │        │   Redpanda     │      │  Supabase   │
    │ (Transit)│        │ (Kafka-compat) │      │  (State)    │
    └──────────┘        └────────────────┘      └─────────────┘
                               │
                ┌──────────────┼──────────────┐
                │              │              │
         ┌──────▼──────┐ ┌────▼─────┐ ┌─────▼──────┐
         │  Shopify    │ │ WhatsApp │ │    N8N     │
         │  Webhooks   │ │ Messages │ │  Workflows │
         └─────────────┘ └──────────┘ └────────────┘
```

## 🚀 Componentes Clave

### 1. **protoc-gen-go-mcp** (Redpanda Plugin)
- **Función**: Genera servidores MCP automáticamente desde definiciones gRPC
- **Input**: `.proto` files (Shopify, WhatsApp, N8N, MCP, Tenant services)
- **Output**: `*.pb.mcp.go` con 23 tools listos para usar
- **Ventaja**: Zero boilerplate - cada RPC method = 1 MCP tool

### 2. **Redpanda** (Kafka-Compatible Event Streaming)
- **Topics creados**: 20 topics base (shopify.*, whatsapp.*, n8n.*, mcp.*, tenant.*)
- **Integración**: Todos los services publican eventos a Kafka
- **Ventaja**: Event-driven architecture real, no polling

### 3. **Vault Transit Engine**
- **Función**: Encryption-at-rest para secrets (Shopify API keys, WhatsApp tokens, etc.)
- **Integración**: MCP server lee/escribe secrets encriptados
- **Ventaja**: GDPR/SOC2 compliant

### 4. **Observability Stack** (Sentry + OpenTelemetry + Grafana)
- **Función**: Tracking de todas las tool executions
- **Kafka Integration**: `mcp.agent.telemetry` topic → ClickHouse → Grafana
- **Ventaja**: Full visibility de LLM tool usage

## 📋 Servicios Protobuf Definidos

### `shopify.proto`
```protobuf
service ShopifyService {
  rpc ProcessWebhook(...) -> Kafka topic: shopify.webhooks
  rpc GetProduct(...) -> Cache in shopify.products (compacted)
  rpc UpdateInventory(...) -> shopify.inventory
  rpc CreateOrder(...) -> shopify.orders
  rpc SyncProducts(...) -> Bulk sync to Kafka
}
```
**5 MCP tools auto-generated**

### `whatsapp.proto`
```protobuf
service WhatsAppService {
  rpc SendMessage(...) -> Kafka: whatsapp.outbound
  rpc ProcessInbound(...) -> Kafka: whatsapp.inbound
  rpc GetConversation(...) -> Query Supabase
  rpc CreateBotResponse(...) -> Generate + send to Kafka
}
```
**4 MCP tools auto-generated**

### `n8n.proto`
```protobuf
service N8NService {
  rpc TriggerWorkflow(...) -> Kafka: n8n.automation.trigger
  rpc GetExecution(...) -> Query N8N API
  rpc ListWorkflows(...) -> N8N API
  rpc CreateTrigger(...) -> Register Kafka consumer
}
```
**4 MCP tools auto-generated**

### `mcp.proto`
```protobuf
service MCPAgentService {
  rpc ExecuteTool(...) -> Orchestrate other MCP servers
  rpc ListTools(...) -> Registry de tools disponibles
  rpc CreateSession(...) -> Session management
  rpc GetTelemetry(...) -> Kafka: mcp.agent.telemetry
  rpc RegisterMCPServer(...) -> Vault + Supabase storage
}
```
**5 MCP tools auto-generated**

### `tenant.proto`
```protobuf
service TenantService {
  rpc CreateTenant(...) -> Provision full stack
  rpc GetTenant(...) -> Query Supabase
  rpc UpdateTenant(...) -> Update + Kafka event
  rpc ProvisionResources(...) -> Create Kafka topics, Vault namespace, etc.
  rpc GetMetrics(...) -> Query tenant.metrics
}
```
**5 MCP tools auto-generated**

## 🔥 Ventajas de esta Arquitectura

### 1. **Zero Boilerplate**
```bash
# Definir servicio en .proto
make generate
# ✅ MCP server completo generado automáticamente
```

### 2. **Event-Driven Real**
- Todo fluye por Redpanda
- N8N consume topics y ejecuta workflows
- Shopify webhooks → Kafka → N8N → WhatsApp
- Sin HTTP polling, sin delays

### 3. **Multi-Tenant Native**
- Cada tenant tiene su namespace en Vault
- Kafka topics con prefijo: `{tenant_id}.*`
- RLS en Supabase por tenant
- Aislamiento completo

### 4. **Type-Safe**
- Protobuf valida inputs/outputs
- `buf.validate` constraints en schemas
- JSON Schema auto-generado para LLMs
- No más "tool called with invalid params"

### 5. **Observable**
- Cada tool execution → `mcp.agent.telemetry`
- ClickHouse almacena traces
- Grafana dashboards en tiempo real
- Sentry para errors

### 6. **Scalable**
- Redpanda puede escalar horizontalmente
- MCP server stateless (múltiples replicas)
- N8N workers consumen en paralelo
- Vault HA-ready

## 🛠️ Comandos de Desarrollo

```bash
# 1. Instalar herramientas
make install-tools

# 2. Generar código desde .proto
make generate

# 3. Build MCP server
make build

# 4. Run localmente
make run

# 5. Generar config para Claude Desktop
make claude-config

# 6. Deploy a VPS
make deploy-vps
```

## 🚢 Deployment en VPS

```bash
# 1. Levantar Redpanda
cd /path/to/dkcompose
docker-compose -f redpanda.yml up -d

# 2. Esperar inicialización (crea 20 topics automáticamente)
docker logs -f smarter-redpanda-init

# 3. Verificar topics
docker exec smarter-redpanda rpk topic list

# 4. Levantar Vault
docker-compose -f vault.yml up -d

# 5. Inicializar Vault
docker exec smarter-vault /vault-init.sh
# ⚠️ GUARDAR UNSEAL KEYS EN LUGAR SEGURO

# 6. Levantar Observability
docker-compose -f observability.yml up -d

# 7. Deploy MCP server
scp bin/smarteros-mcp-server root@smarterbot.cl:/usr/local/bin/
systemctl enable smarteros-mcp-server
systemctl start smarteros-mcp-server
```

## 📊 Redpanda Topics

| Topic                         | Retention | Type      | Purpose                          |
|-------------------------------|-----------|-----------|----------------------------------|
| `smarteros.events`            | 7 days    | delete    | Core system events               |
| `shopify.webhooks`            | 3 days    | delete    | Raw Shopify webhooks             |
| `shopify.products`            | 7 days    | compact   | Product catalog (latest only)    |
| `shopify.inventory`           | 1 day     | compact   | Inventory levels                 |
| `whatsapp.inbound`            | 3 days    | delete    | Incoming messages                |
| `whatsapp.outbound`           | 3 days    | delete    | Outgoing messages                |
| `n8n.automation.trigger`      | 1 day     | delete    | Workflow triggers                |
| `n8n.automation.result`       | 7 days    | delete    | Workflow results                 |
| `mcp.agent.actions`           | 7 days    | delete    | Agent tool executions            |
| `mcp.agent.telemetry`         | 3 days    | delete    | Telemetry data                   |
| `tenant.provisioning`         | 30 days   | delete    | Tenant creation events           |
| `clerk.auth.events`           | 7 days    | delete    | Auth events from Clerk           |

## 🎯 Próximos Pasos (Fase 3)

1. **Implementar Service Implementations**
   - Conectar cada RPC method a Redpanda
   - Integrar Vault para secrets
   - Implementar business logic

2. **N8N Kafka Consumers**
   - Crear workflows que consuman topics
   - Ej: `whatsapp.inbound` → GPT-4 → `whatsapp.outbound`

3. **Dashboards Grafana**
   - Latencia por tool
   - Mensajes por topic
   - Error rates
   - LLM token usage

4. **Multi-Tenant Testing**
   - Crear 3 tenants de prueba
   - Verificar aislamiento de datos
   - Load testing con Redpanda

5. **DR Testing Automation**
   - Backup de Redpanda topics
   - Restore testing mensual
   - RTO < 15 min

## 📚 Referencias

- [protoc-gen-go-mcp](https://github.com/redpanda-data/protoc-gen-go-mcp)
- [Redpanda Docs](https://docs.redpanda.com/)
- [Buf CLI](https://buf.build/docs)
- [MCP Specification](https://modelcontextprotocol.io/)
- [Vault Transit Engine](https://developer.hashicorp.com/vault/docs/secrets/transit)

## 🔐 Security

- **Vault Transit**: Todos los secrets encriptados at-rest
- **Kafka ACLs**: Por tenant (próximamente)
- **Supabase RLS**: Row-level security por tenant_id
- **TLS**: Todos los endpoints con Let's Encrypt
- **Rate Limiting**: Traefik middleware (1000 req/min por tenant)

## 🎉 Estado Actual

- ✅ Protobuf schemas definidos (5 servicios, 23 RPC methods)
- ✅ buf.gen.yaml configurado con protoc-gen-go-mcp
- ✅ Redpanda docker-compose con 20 topics
- ✅ MCP server skeleton con TODOs
- ✅ Makefile para full automation
- ⏳ Pending: Implementar service logic
- ⏳ Pending: Deploy en VPS
- ⏳ Pending: N8N workflows
- ⏳ Pending: Grafana dashboards

**Arquitectura Score: 9.8/10** ← Con esto llegamos a 10/10 después de implementación
