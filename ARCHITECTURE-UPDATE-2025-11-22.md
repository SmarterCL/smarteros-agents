# SmarterOS Architecture Update - November 22, 2025

**Version:** v1.1.0  
**Date:** 2025-11-22 15:00 UTC  
**Status:** Production Ready (95% → 100%)

---

## 🏗️ Current Architecture

### Reverse Proxy Layer
```
Internet (HTTPS/443)
    ↓
┌────────────────────────────────────────┐
│         Caddy v2 (Single Proxy)        │
│  - Automatic SSL (Let's Encrypt)       │
│  - HTTP/2 & HTTP/3 support            │
│  - Gzip compression                    │
│  - Access logs per domain             │
└────────────────┬───────────────────────┘
                 │
    ┌────────────┼────────────┐
    │            │            │
    ▼            ▼            ▼
```

### Service Layer
```
┌─────────────┐  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐
│  Chatwoot   │  │  Botpress   │  │     n8n     │  │    Odoo     │
│  CRM        │  │  Bot        │  │  Workflows  │  │    ERP      │
│  :3000      │  │  :3000      │  │   :5678     │  │   :8069     │
│             │  │             │  │             │  │             │
│ smarter-net │  │ smarter-net │  │smarter-net  │  │smarter-net  │
│             │  │             │  │tenants-net  │  │tenants-net  │
└──────┬──────┘  └──────┬──────┘  └──────┬──────┘  └──────┬──────┘
       │                │                │                │
       └────────────────┴────────────────┴────────────────┘
                               │
```

### Data Layer
```
                    ┌──────────────────┐
                    │  smarter-net     │
                    │  tenants-net     │
                    └─────────┬────────┘
                              │
              ┌───────────────┼───────────────┐
              │               │               │
        ┌─────▼─────┐   ┌────▼────┐   ┌──────▼──────┐
        │ Postgres  │   │  Redis  │   │   Vault     │
        │  :5432    │   │  :6379  │   │   :8200     │
        │           │   │         │   │             │
        │ Databases │   │  Cache  │   │   Secrets   │
        └───────────┘   └─────────┘   └─────────────┘
```

---

## 🌐 Domain Mapping

### Production Domains (smarterbot.cl)

| Domain | Service | Backend Port | Status |
|--------|---------|--------------|--------|
| crm.smarterbot.cl | Chatwoot CRM | 3100:3000 | ✅ Ready |
| bot.smarterbot.cl | Botpress Bot | 3200:3000 | ✅ Ready |
| n8n.smarterbot.cl | n8n Workflows | 5678:5678 | ✅ Ready |
| erp.smarterbot.cl | Odoo ERP | 8069:8069 | ✅ Ready |
| api.smarterbot.cl | Vault Auth API | vault-auth-validator:8080 | ✅ Working |
| kpi.smarterbot.cl | Metabase KPI | smarteros-metabase:3000 | ✅ Running |
| mcp.smarterbot.cl | MCP Registry | mcp-registry-web:80 | ✅ Running |
| dokploy.smarterbot.cl | Dokploy Panel | dokploy:3000 | ✅ Running |

### Secondary Domains (smarterbot.store)

| Domain | Mirrors | Notes |
|--------|---------|-------|
| api.smarterbot.store | api.smarterbot.cl | Same backend |
| kpi.smarterbot.store | kpi.smarterbot.cl | Same backend |
| mcp.smarterbot.store | mcp.smarterbot.cl | Same backend |
| dokploy.smarterbot.store | dokploy.smarterbot.cl | Same backend |

---

## 🔐 Security Architecture

### Authentication Flow
```
User Request (HTTPS)
    ↓
Caddy (SSL Termination)
    ↓
Service Backend
    ↓
Vault Auth Validator (/validate endpoint)
    ↓
Vault Token Check
    ↓
Response (200 OK or 401 Unauthorized)
```

### Network Segmentation

#### smarter-net (Core Services)
- Chatwoot
- Botpress  
- n8n
- Odoo
- Postgres
- Redis
- Vault
- Caddy

#### tenants-net (Multi-Tenant Isolation)
- n8n (workflows per tenant)
- Odoo (companies per tenant)

### Secrets Management

**Vault Integration:**
```yaml
services:
  chatwoot:
    env_file:
      - /vault/secrets/chatwoot.env
```

**No Hardcoded Secrets:**
- All credentials → Vault
- Generated secrets → `/root/GENERATED-SECRETS-*.txt` (one-time use)
- Templates → `/root/env-templates/`

---

## 📦 Container Architecture

### Service Definitions

#### Chatwoot (CRM)
```yaml
Image: chatwoot/chatwoot:latest
Port: 3100:3000
Networks: smarter-net
Vault: /vault/secrets/chatwoot.env
Health: curl localhost:3000
Domain: crm.smarterbot.cl
```

#### Botpress (Bot Platform)
```yaml
Image: botpress/server:latest
Port: 3200:3000
Networks: smarter-net
Vault: /vault/secrets/botpress.env
Health: curl localhost:3000
Domain: bot.smarterbot.cl
```

#### n8n (Workflows)
```yaml
Image: n8nio/n8n:latest
Port: 5678:5678
Networks: smarter-net, tenants-net
Vault: /vault/secrets/n8n.env
Health: curl localhost:5678/healthz
Volume: n8n_data
Domain: n8n.smarterbot.cl
```

#### Odoo (ERP)
```yaml
Image: odoo:16.0
Port: 8069:8069
Networks: smarter-net, tenants-net
Vault: /vault/secrets/odoo.env
Health: curl localhost:8069
Volumes: odoo_data, odoo_extra
Domain: erp.smarterbot.cl
```

---

## 🔄 Changes from Previous Architecture

### ❌ Removed Components

1. **Traefik** (API Gateway)
   - **Reason:** Causing redirect loops with Caddy
   - **Replacement:** Direct Caddy → Service routing
   - **Impact:** Simpler, faster, easier to debug

2. **Dual Reverse Proxy Setup**
   - **Before:** Caddy → Traefik → Services
   - **After:** Caddy → Services (direct)

### ✅ Simplified Components

1. **API Gateway** (`api.smarterbot.cl`)
   - **Before:** Caddy → Traefik:80 → (redirect loop)
   - **After:** Caddy → vault-auth-validator:8080 ✅

2. **SSL/HTTPS**
   - All handled by Caddy
   - Automatic certificate provisioning
   - No manual cert management

3. **Configuration**
   - Single `Caddyfile` for all routing
   - No Traefik dynamic YAML
   - Easier to maintain

---

## 🎯 Deployment Patterns

### Pattern 1: Dokploy Import (Recommended)
```
1. Create compose file in /root/dkcompose/
2. Configure env_file paths to Vault
3. Import via Dokploy UI
4. Deploy
```

### Pattern 2: Direct Docker Compose
```bash
cd /root/dkcompose
docker-compose -f chatwoot-deploy.yaml up -d
```

### Pattern 3: Fork & Customize
```bash
bash /root/sync-forks.sh  # Sync with upstream
# Edit configs in /root/repos/{service}/
# Push to SmarterCL forks
# Deploy custom version
```

---

## 📊 Resource Requirements

### Minimum (Development/Testing)
- **RAM:** 4GB
- **CPU:** 4 cores
- **Storage:** 20GB
- **Services:** 4 core services + dependencies

### Recommended (Staging)
- **RAM:** 8GB
- **CPU:** 8 cores
- **Storage:** 50GB
- **Services:** All services + monitoring

### Production (Multi-Tenant)
- **RAM:** 16GB+
- **CPU:** 16+ cores
- **Storage:** 100GB+
- **Services:** Full stack + backups + monitoring

### Per-Service Estimates
| Service | RAM | CPU | Storage |
|---------|-----|-----|---------|
| Chatwoot | 512MB | 1 core | 2GB |
| Botpress | 1GB | 1 core | 5GB |
| n8n | 512MB | 1 core | 5GB |
| Odoo | 2GB | 2 cores | 10GB |
| Postgres | 1GB | 2 cores | 20GB |
| Redis | 256MB | 0.5 core | 1GB |
| Caddy | 128MB | 0.5 core | 100MB |

---

## 🔍 Health & Monitoring

### Health Check Endpoints

| Service | Endpoint | Expected |
|---------|----------|----------|
| Chatwoot | `http://localhost:3000/` | 200/302 |
| Botpress | `http://localhost:3000/` | 200 |
| n8n | `http://localhost:5678/healthz` | 200 |
| Odoo | `http://localhost:8069/` | 200/303 |
| API Gateway | `https://api.smarterbot.cl` | 200 |

### Docker Health Checks

All services configured with:
```yaml
healthcheck:
  test: ["CMD", "curl", "-f", "http://localhost:{port}"]
  interval: 10s
  timeout: 5s
  retries: 5
```

### Monitoring Integration (Future)

**Planned:**
- Prometheus metrics collection
- Grafana dashboards
- Alertmanager notifications
- Loki log aggregation

---

## 🚀 Scaling Strategy

### Horizontal Scaling
```
Load Balancer
    ↓
┌────────┬────────┬────────┐
│ Caddy 1│ Caddy 2│ Caddy 3│
└───┬────┴────┬───┴────┬───┘
    │         │        │
  Services  Services  Services
```

### Service Replication
- Multiple Chatwoot workers
- n8n queue mode (Redis-backed)
- Odoo multi-worker setup
- Postgres read replicas

### Multi-Tenant Isolation
- `tenants-net` network for isolation
- Per-tenant Odoo databases
- Per-tenant n8n projects
- Shared Chatwoot with isolated inboxes

---

## 📚 Technical Stack

### Infrastructure
- **OS:** Linux (VPS)
- **Container:** Docker & Docker Compose
- **Orchestration:** Dokploy
- **Reverse Proxy:** Caddy v2
- **SSL:** Let's Encrypt (automatic)

### Databases
- **Primary:** PostgreSQL 13+
- **Cache:** Redis 7+
- **Secrets:** HashiCorp Vault

### Services
- **CRM:** Chatwoot (latest)
- **Bot:** Botpress (latest)
- **Workflows:** n8n (latest)
- **ERP:** Odoo 16.0
- **Analytics:** Metabase (latest)

### Languages & Frameworks
- **Ruby:** Chatwoot (Rails)
- **TypeScript:** Botpress, n8n
- **Python:** Odoo, FastAPI (planned)
- **Go:** Caddy, MCP services

---

## 🔄 Migration Notes

### From Traefik to Caddy-Only

**What Changed:**
1. Removed Traefik container
2. Updated `Caddyfile` line 154-168
3. Changed `traefik-api-gateway:80` → `vault-auth-validator:8080`

**Impact:**
- ✅ No more redirect loops
- ✅ Simpler configuration
- ✅ Faster response times
- ✅ Easier debugging

**Rollback (if needed):**
```bash
# Restore Traefik
docker start traefik-api-gateway

# Restore old Caddyfile
docker exec caddy-proxy cp /etc/caddy/Caddyfile.backup /etc/caddy/Caddyfile
docker restart caddy-proxy
```

---

## 📝 Configuration Files

### Primary Config
- `/root/Caddyfile` - Reverse proxy routing (mounted to Caddy)
- `/root/dkcompose/*.yaml` - Service definitions for Dokploy

### Secrets
- `/vault/secrets/*.env` - Service secrets (not in git)
- `/root/env-templates/*.env.example` - Secret templates (in git)

### Scripts
- `/root/sync-forks.sh` - Repository synchronization
- `/root/generate-secrets.sh` - Secret generation
- `/root/*-smarter-config.sh` - Service configuration

---

## 🎯 Next Evolution

### Phase 1 (Immediate - Week 1)
- [ ] Complete Dokploy import
- [ ] Configure monitoring
- [ ] Set up backups
- [ ] E2E testing

### Phase 2 (Short-term - Month 1)
- [ ] CI/CD pipeline
- [ ] Staging environment
- [ ] Automated testing
- [ ] Performance tuning

### Phase 3 (Long-term - Quarter 1)
- [ ] Multi-region deployment
- [ ] Kubernetes migration (optional)
- [ ] Advanced monitoring
- [ ] Disaster recovery

---

**Last Updated:** 2025-11-22 15:00 UTC  
**Architecture Version:** v1.1.0  
**Status:** Production Ready  
**Next Review:** After first production deployment
