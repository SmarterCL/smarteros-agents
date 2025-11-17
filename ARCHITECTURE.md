# ARCHITECTURE.md - Estructura SmarterOS

> **ACTUALIZADO**: 2025-11-16 — Añadido **Tier 0: Infrastructure** con Hostinger API MCP para gestión autónoma de infraestructura.

---

## 🏗️ Arquitectura General

```
┌──────────────────────────────────────────────────────────┐
│               SMARTEROS OPERATING SYSTEM                 │
│                 (AI-Managed Infrastructure)              │
│                                                          │
│  ┌─────────────────────────────────────────────────┐    │
│  │ 🎯 TIER 0: Infrastructure (NUEVO - AI Control) │    │
│  │                                                 │    │
│  │  • Hostinger API MCP (VPS Lifecycle)           │    │
│  │  • VPS: Start/Stop/Reboot/Backup/Restore       │    │
│  │  • SSH Keys Management (API)                   │    │
│  │  • Firewall Configuration                      │    │
│  │  • Docker Projects Management                  │    │
│  │  • Domain Registration & DNS                   │    │
│  │  • Billing & Usage Monitoring                  │    │
│  │                                                 │    │
│  │  Primary Agent: executor-codex                 │    │
│  │  Secondary Agent: director-gemini (read-only)  │    │
│  │  Vault: smarteros/mcp/hostinger                │    │
│  └─────────────────────────────────────────────────┘    │
│             ↓ Controls & Provisions ↓                    │
│                                                          │
│  ┌──────────────┐  ┌──────────────┐                    │
│  │   Frontend   │  │   Backend    │                    │
│  │              │  │              │                    │
│  │ • app.smarterbot.cl (Next.js)  │                    │
│  │ • smarterbot.store (Shopify)   │                    │
│  └──────────────┘  └──────────────┘                    │
│                                                          │
│  ┌────────────────────────────────────────────────┐     │
│  │         Core Services Layer (TIER 1)           │     │
│  │                                                │     │
│  │  • Odoo (ERP)                                 │     │
│  │  • N8N (Automation)                           │     │
│  │  • Supabase (Database)                        │     │
│  │  • Metabase (Analytics)                       │     │
│  │  • Vault (Secrets) ← Core Infrastructure     │     │
│  └────────────────────────────────────────────────┘     │
│                                                          │
│  ┌────────────────────────────────────────────────┐     │
│  │       Communication Layer (TIER 4)             │     │
│  │                                                │     │
│  │  • Chatwoot (CRM)                             │     │
│  │  • Botpress (AI Bots)                         │     │
│  │  • WhatsApp Business API                      │     │
│  └────────────────────────────────────────────────┘     │
│                                                          │
│  ┌────────────────────────────────────────────────┐     │
│  │    Physical Infrastructure (SSH Direct)        │     │
│  │                                                │     │
│  │  • Hostinger VPS: 89.116.23.167               │     │
│  │    - CPU: 2 cores                             │     │
│  │    - RAM: 4GB                                 │     │
│  │    - Disk: 100GB SSD                          │     │
│  │    - OS: Ubuntu 24.04 LTS                     │     │
│  │                                                │     │
│  │  • Dokploy (Container Orchestration)          │     │
│  │  • Traefik (Reverse Proxy & SSL)              │     │
│  │  • Cloudflare (DNS, CDN, DDoS Protection)     │     │
│  └────────────────────────────────────────────────┘     │
│                                                          │
│  ┌────────────────────────────────────────────────┐     │
│  │      Integration Layer (25 MCP Providers)      │     │
│  │                                                │     │
│  │  Tier 0: Hostinger                            │     │
│  │  Tier 1: GitHub, Docker, Vault, Supabase      │     │
│  │  Tier 2: N8N, Odoo, Shopify, Metabase         │     │
│  │  Tier 3: Claude, Context7, Deepgram, Assembly │     │
│  │  Tier 4: Slack, WhatsApp, Chatwoot, Telegram  │     │
│  │  Tier 5: AWS, Cloudflare, Sentry, PostHog     │     │
│  └────────────────────────────────────────────────┘     │
└──────────────────────────────────────────────────────────┘
```

---

## 🎯 Tier 0: Infrastructure Autonomy (NUEVO)

**Hostinger API MCP** permite que el tri-agente gestione infraestructura de forma autónoma:

### 🤖 Capacidades AI-Managed

1. **VPS Lifecycle Management**
   - Codex puede: start, stop, reboot, purchase, setup VPS
   - Auto-recovery: Si VPS cae, Codex lo detecta y restaura desde backup
   - Scaling: Crear nuevos VPS para tenants enterprise on-demand

2. **Automated Backups & Recovery**
   - Backups diarios automáticos (2am)
   - Retención 7 días con cleanup automático
   - Disaster recovery con un comando: `/restore-vps <backup_id>`

3. **SSH Keys API Management**
   - Rotación automática mensual de SSH keys
   - Deploy keys por tenant con acceso granular
   - Cleanup de keys antiguas (mantiene últimas 2)

4. **Firewall & Security**
   - Activar firewalls production automáticamente
   - Reglas por tenant con aislamiento de red
   - Monitoreo de seguridad con alertas a Slack

5. **Docker Projects**
   - Updates automáticos de n8n/Odoo/Metabase
   - Health checks post-update
   - Rollback automático si falla

6. **Domain Operations**
   - Check availability para nuevos tenants
   - Enable WHOIS privacy automáticamente
   - Configure domain forwarding

7. **Billing Automation**
   - Monitor usage y costos por tenant
   - Alertas cuando se acerca límite de plan
   - Auto-upgrade si tenant crece

### 🔐 Acceso Dual (Complementario)

**API MCP** (Management Operations)
- Vault: `smarteros/mcp/hostinger`
- Auth: Bearer token (api_token)
- Agent: executor-codex (primary), director-gemini (read-only)
- Use: VPS lifecycle, backups, firewall, domains, billing

**SSH Direct** (Deploy Operations)
- Vault: `smarteros/ssh/deploy`
- Auth: Ed25519 key pair (private_key, public_key)
- Agent: executor-codex
- Use: rsync files, systemctl, shell commands, log access

Ambos métodos coexisten y se complementan. API MCP controla la infraestructura, SSH direct ejecuta deploys.

---

## 🔌 Multi-Tenant Architecture

Cada tenant tiene:
- Subdominio Shopify propio
- Base de datos aislada (RLS)
- Workflows N8N dedicados
- KPIs Metabase propios
- WhatsApp Business propio

## 🔄 Data Flow

1. Cliente → WhatsApp → Chatwoot → Bot IA
2. Pedido → Shopify → N8N → Odoo → Facturación
3. Envío → BlueExpress → Tracking → WhatsApp
4. Métricas → Metabase → Dashboard → Decisiones
