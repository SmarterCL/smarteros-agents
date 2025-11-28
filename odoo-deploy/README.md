# Odoo 19 Minimal Deployment (Source Build + FastAPI Integration)

## 1. Build & Run (Local)
```bash
cd odoo-deploy
cp .env.sample .env   # edit ODOO_API_KEY after generation
docker compose build  # builds from cloned smartercl-odoo source
docker compose up -d
```
Access UI: http://localhost:8069

If build fails (missing Dockerfile or heavy source build), fallback to official image:
- Comment out `build:` section
- Uncomment `image: odoo:19.0`
- Re-run `docker compose up -d`

## 2. Volumes
- `postgres_data`: Postgres cluster persistence
- `odoo_data`: Odoo filestore & config runtime path
- `odoo_extra_addons`: Place custom addons here (map in UI: Settings > Apps > Activate Developer Mode > Apps path)

Backup example:
```bash
docker compose stop odoo
docker run --rm -v odoo-deploy_postgres_data:/var/lib/postgresql/data -v $(pwd):/backup alpine tar czf /backup/postgres_data_$(date +%Y%m%d).tgz /var/lib/postgresql/data
docker run --rm -v odoo-deploy_odoo_data:/var/lib/odoo -v $(pwd):/backup alpine tar czf /backup/odoo_data_$(date +%Y%m%d).tgz /var/lib/odoo
```

## 3. Generate API Key (After Initial Setup)
1. Create database `smarterbot` (first web screen) & set admin password.
2. Log in as admin.
3. Go to top-right avatar > "My Profile".
4. Click "Account Security" (or "API Keys" in newer UI).
5. Generate new API key; copy it.
6. Update `.env` with `ODOO_API_KEY`.

## 4. FastAPI Integration
Ensure FastAPI service has these environment variables exported before start:
- `ODOO_URL` (local: http://localhost:8069 or public HTTPS domain)
- `ODOO_DB` (smarterbot)
- `ODOO_API_KEY` (generated)

Test JSON-2 endpoint manually:
```bash
curl -X POST "$ODOO_URL/json/2/res.partner/search_read" \
 -H "Authorization: Bearer $ODOO_API_KEY" \
 -H "X-Odoo-Database: $ODOO_DB" \
 -H 'Content-Type: application/json' \
 -d '{"domain": [], "fields": ["name"], "limit": 1}'
```
Expected: `{ "data": [...], "length": 1 }`

## 5. Caddy Reverse Proxy Snippet
Example (replace domain):
```
erp.smarterbot.store {
    encode gzip
    reverse_proxy 127.0.0.1:8069 {
        header_up X-Forwarded-Proto {scheme}
        header_up X-Forwarded-Host {host}
    }
}
```
Reload:
```bash
caddy reload --config /etc/caddy/Caddyfile
```

## 6. Health & Validation Checklist
- Port 8069 reachable locally (HTTP 200 + full HTML login page).
- JSON-2 `search_read` returns non-empty body.
- FastAPI `/odoo/search_read` (your new router) returns same structure.
- No filestore errors in `docker logs odoo` during basic operations.

## 7. Performance & Next Steps
- Add workers: adjust command with `--workers 4` once stable.
- Enable longpolling: expose port 8072 if needed.
- Add Prometheus sidecar (future) scraping custom FastAPI metrics.
- Implement automation: product sync, stock updates via n8n using FastAPI endpoints.

## 8. Common Issues
- Empty external body via proxy: ensure reverse_proxy does not strip response; avoid caching middlewares; confirm `Content-Length` not zero from upstream.
- ACME rate limit: fix DNS first, wait before re-issuing cert.

---
Minimal, source-first approach prepared for rapid iteration.
