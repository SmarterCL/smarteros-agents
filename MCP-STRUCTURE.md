# Estructura MCP SmarterOS

## MCPs activos
- GitHub (repo, issues, PR, releases)
- Context7 (documentación, AI agents)
- Cloudflare (DNS, seguridad)
- Hostinger (VPS, backups, firewall)
- Shopify (multi-tenant commerce)
- Supabase (auth, storage, DB)
- Docker (containers, infra)

## Integración en la arquitectura
- Todos los servicios conversan vía MCPs
- Los agentes Codex operan sobre MCPs
- El spec-repo es el cerebro versionado del OS
- Los tokens viven en `system/env/local/.env.*` (nunca en GitHub)
- El daily loop se orquesta con workflows MCP (n8n, backups, deploys)

## Ejemplo de flujo MCP
1. Codex Agent detecta cambio en specs
2. MCP-GitHub crea issue y PR
3. MCP-Hostinger ejecuta backup y firewall
4. MCP-Shopify actualiza storefront por tenant
5. MCP-Supabase valida auth y storage
6. MCP-Cloudflare actualiza DNS
7. MCP-Docker reinicia containers

---

**SmarterOS = OS multi-tenant, versionado, automatizado y seguro, gracias a MCPs.**
