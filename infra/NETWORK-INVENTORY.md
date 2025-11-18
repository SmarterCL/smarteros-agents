# SmarterOS Network & DNS Inventory

**Last Updated**: 2025-11-18  
**Environment**: Production (Hostinger VPS)  
**IP Address**: 89.116.23.167

---

## DNS Configuration

### Domain: smarterbot.cl

| Subdomain | Type | Target | Purpose | Status |
|-----------|------|--------|---------|--------|
| kpi | A | 89.116.23.167 | Metabase Dashboard | ✅ Active |
| chatwoot | A | 89.116.23.167 | Customer Support | ✅ Active |
| chat | A | 89.116.23.167 | Botpress | ✅ Active |
| n8n | A | 89.116.23.167 | Workflow Automation | ✅ Active |
| odoo | A | 89.116.23.167 | ERP System | ✅ Active |
| portainer | A | 89.116.23.167 | Container Management | ✅ Active |
| dokploy | A | 89.116.23.167 | Deployment Platform | ✅ Active |
| mkt | A | 89.116.23.167 | BlogBowl Marketing | ✅ Active |

### Domain: smarterbot.store (Hostinger)

| Subdomain | Type | Target | Purpose | Status |
|-----------|------|--------|---------|--------|
| dokploy | A | 89.116.23.167 | Deployment Platform (alt) | ✅ Active |
| ai | A | 89.116.23.167 | Nexa AI Runtime | ✅ Active |
| mkt | A | 89.116.23.167 | BlogBowl Marketing (alt) | ✅ Active |

---

## Docker Networks

| Network Name | Driver | Scope | Purpose |
|--------------|--------|-------|---------|
| smarter-net | bridge | local | Main SmarterOS services network |
| dokploy-network | overlay | swarm | Dokploy internal orchestration |
| dokploy_default | overlay | swarm | Dokploy deployed services |
| code_smarter-net | bridge | local | Development/staging network |

---

## Container to Network Mapping

| Container | Network | Internal Port | External Port | Domain |
|-----------|---------|---------------|---------------|--------|
| smarteros-metabase | smarter-net | 3000 | - | kpi.smarterbot.cl |
| smarter-chatwoot | smarter-net | 3000 | - | chatwoot.smarterbot.cl |
| smarter-n8n | smarter-net | 5678 | - | n8n.smarterbot.cl |
| dokploy | dokploy-network | 3000 | 3000 | dokploy.smarterbot.{cl,store} |
| nexa-server | smarter-net | 8000 | 8000 | ai.smarterbot.store |
| smarteros-blogbowl | smarter-net | 3000 | 3002 | mkt.smarterbot.{cl,store} |

---

## Reverse Proxy Configuration (Caddy)

### SSL/TLS
- **Provider**: Let's Encrypt (automatic)
- **Email**: admin@smarterbot.cl
- **Auto HTTPS**: Enabled (except for direct IP)

### Logs
- **Location**: `/var/log/caddy/`
- **Format**: Per-domain log files

### Special Rules
- Direct IP (http://89.116.23.167) → Redirects to https://dokploy.smarterbot.store
- All services use gzip encoding
- Headers forwarded for proper proxying

---

## Network Security

### Open Ports
- 80 (HTTP - Caddy)
- 443 (HTTPS - Caddy)
- 3000 (Dokploy direct access)
- 3002 (BlogBowl direct access - optional)
- 8000 (Nexa AI direct access - optional)

### Firewall Recommendations
```bash
# UFW rules (recommended)
ufw allow 80/tcp
ufw allow 443/tcp
ufw allow 3000/tcp  # Dokploy
ufw deny 3002/tcp   # Close direct BlogBowl access
ufw deny 8000/tcp   # Close direct Nexa access
```

---

## Internal Service Discovery

Services on `smarter-net` can communicate via container names:

```
smarteros-metabase:3000
smarter-chatwoot:3000
smarter-n8n:5678
nexa-server:8000
smarteros-blogbowl:3000
dokploy:3000
```

---

## Health Checks

| Service | Health Endpoint | Expected Response |
|---------|-----------------|-------------------|
| Metabase | http://smarteros-metabase:3000/api/health | 200 OK |
| Chatwoot | http://smarter-chatwoot:3000/health | 200 OK |
| n8n | http://smarter-n8n:5678/healthz | 200 OK |
| Nexa | http://nexa-server:8000/health | 200 OK |
| BlogBowl | http://smarteros-blogbowl:3000/ | 200 OK |
| Dokploy | http://dokploy:3000/ | 200 OK |

---

## Troubleshooting

### Common Issues

**ERR_SSL_PROTOCOL_ERROR on direct IP**
- Expected behavior - IP redirects to domain
- Solution: Use domain names instead

**502 Bad Gateway**
- Check container status: `docker ps`
- Check container logs: `docker logs <container-name>`
- Verify network attachment: `docker inspect <container-name>`

**Gateway Timeout**
- Container might be starting
- Check healthcheck: `docker inspect <container-name> | grep Health`
- Restart if needed: `docker restart <container-name>`

### Validation Commands

```bash
# Check all services
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

# Check networks
docker network ls

# Test internal connectivity
docker exec smarteros-blogbowl curl -I http://nexa-server:8000/health

# Check Caddy config
docker exec caddy caddy validate --config /etc/caddy/Caddyfile

# Reload Caddy
docker exec caddy caddy reload --config /etc/caddy/Caddyfile
```

---

## Next Steps

1. ✅ Close direct ports (3002, 8000) via firewall
2. ✅ Set up monitoring for all health endpoints
3. ✅ Configure Metabase dashboard for network metrics
4. ⏳ Implement rate limiting in Caddy
5. ⏳ Add DDoS protection via Cloudflare (optional)

---

## Related Documentation

- [Deployment Guide](../DEPLOYMENT-GUIDE.md)
- [Nexa Integration](../NEXA-INTEGRATION-GUIDE.md)
- [Services Overview](../SERVICES.md)
- [Vault Configuration](../vault/README.md)
