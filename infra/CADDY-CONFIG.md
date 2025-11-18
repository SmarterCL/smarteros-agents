# Caddy Reverse Proxy Configuration

**Version**: Caddy v2  
**Location**: `/root/Caddyfile`  
**Container**: caddy:latest  

---

## Configuration Overview

SmarterOS uses Caddy as the main reverse proxy and SSL termination point for all services.

### Key Features
- ✅ Automatic HTTPS with Let's Encrypt
- ✅ HTTP/2 and HTTP/3 support
- ✅ Gzip compression on all routes
- ✅ Per-domain logging
- ✅ Header forwarding for proxied services
- ✅ Multi-domain support (.cl and .store)

---

## Global Configuration

```caddyfile
{
    email admin@smarterbot.cl
    auto_https disable_redirects
}
```

### Options Explained
- `email`: Contact email for Let's Encrypt certificates
- `auto_https disable_redirects`: Prevents automatic redirects on IP addresses

---

## Domain Mappings

### Production Services (.cl domain)

| Domain | Backend | Port | Container |
|--------|---------|------|-----------|
| kpi.smarterbot.cl | smarteros-metabase | 3000 | Metabase |
| chatwoot.smarterbot.cl | smarter-chatwoot | 3000 | Chatwoot |
| chat.smarterbot.cl | smarter-botpress | 3000 | Botpress |
| n8n.smarterbot.cl | smarter-n8n | 5678 | n8n |
| odoo.smarterbot.cl | smarter-odoo | 8069 | Odoo |
| portainer.smarterbot.cl | smarter-portainer | 9000 | Portainer |
| dokploy.smarterbot.cl | dokploy | 3000 | Dokploy |
| mkt.smarterbot.cl | smarteros-blogbowl | 3000 | BlogBowl |

### Alternative Domain (.store - Hostinger)

| Domain | Backend | Notes |
|--------|---------|-------|
| dokploy.smarterbot.store | dokploy:3000 | Primary Dokploy access |
| ai.smarterbot.store | nexa-server:8000 | Nexa AI Runtime |
| mkt.smarterbot.store | smarteros-blogbowl:3000 | BlogBowl alternative |

---

## Special Routes

### Direct IP Access
```caddyfile
http://89.116.23.167 {
    redir https://dokploy.smarterbot.store{uri} permanent
}
```
**Purpose**: Redirects bare IP access to main Dokploy interface

---

## Proxy Headers

All proxied services receive these headers:

```caddyfile
header_up X-Forwarded-Proto {scheme}
header_up X-Forwarded-For {remote_host}
header_up X-Real-IP {remote_host}
```

**Why**: Ensures backend services know the original client IP and protocol.

---

## Logging

### Log Location
All domain logs are stored in: `/var/log/caddy/`

### Log Files
- `kpi.log` - Metabase access logs
- `chatwoot.log` - Chatwoot access logs
- `chat.log` - Botpress access logs
- `n8n.log` - n8n access logs
- `odoo.log` - Odoo access logs
- `portainer.log` - Portainer access logs
- `dokploy.log` - Dokploy access logs
- `ai.log` - Nexa AI access logs
- `mkt.log` - BlogBowl access logs

### Viewing Logs
```bash
# Real-time monitoring
docker exec caddy tail -f /var/log/caddy/mkt.log

# All logs
docker exec caddy ls -lh /var/log/caddy/

# Grep for errors
docker exec caddy grep -i error /var/log/caddy/*.log
```

---

## SSL/TLS Configuration

### Automatic Certificates
Caddy automatically:
1. Requests certificates from Let's Encrypt
2. Renews certificates before expiration
3. Serves HTTPS on port 443
4. Redirects HTTP (80) to HTTPS (443)

### Certificate Storage
Certificates are stored in: `/data/caddy/certificates/`

### Manual Certificate Check
```bash
docker exec caddy caddy list-certificates
```

---

## Compression

All routes use gzip compression:
```caddyfile
encode gzip
```

**Benefits**:
- Reduces bandwidth usage
- Faster page loads
- Better SEO scores

---

## Health Checks

Caddy itself doesn't have a built-in healthcheck endpoint, but you can verify:

```bash
# Check if Caddy is running
docker ps | grep caddy

# Validate configuration
docker exec caddy caddy validate --config /etc/caddy/Caddyfile

# Check process
docker exec caddy ps aux | grep caddy
```

---

## Reload Configuration

After modifying `/root/Caddyfile`:

```bash
# Reload without downtime
docker exec caddy caddy reload --config /etc/caddy/Caddyfile

# Or restart container
docker restart caddy
```

---

## Adding a New Domain

### Step 1: Add DNS Record
In your DNS provider (Hostinger, etc.):
```
Type: A
Name: newservice
Value: 89.116.23.167
TTL: Auto
```

### Step 2: Add to Caddyfile
```caddyfile
newservice.smarterbot.cl {
    reverse_proxy container-name:port
    encode gzip
    log {
        output file /var/log/caddy/newservice.log
    }
}
```

### Step 3: Reload Caddy
```bash
docker exec caddy caddy reload --config /etc/caddy/Caddyfile
```

### Step 4: Test
```bash
curl -I https://newservice.smarterbot.cl
```

---

## Troubleshooting

### SSL Error (ERR_SSL_PROTOCOL_ERROR)

**Cause**: Accessing via HTTP when HTTPS is enforced, or IP instead of domain.

**Solution**: 
- Use `https://` prefix
- Use domain name instead of IP
- Wait for Let's Encrypt certificate (can take 1-2 minutes)

### 502 Bad Gateway

**Possible causes**:
1. Backend container not running
2. Wrong container name in Caddyfile
3. Wrong port in Caddyfile
4. Container not on same network

**Debug**:
```bash
# Check container
docker ps | grep container-name

# Check network
docker inspect container-name | grep NetworkMode

# Check logs
docker logs container-name

# Test internal connectivity
docker exec caddy curl http://container-name:port
```

### 504 Gateway Timeout

**Cause**: Backend service taking too long to respond.

**Solution**:
1. Check backend service health
2. Increase timeout (add to specific route):
```caddyfile
reverse_proxy container:port {
    timeout 300s
}
```

### Certificate Issues

**Check certificate status**:
```bash
docker exec caddy caddy list-certificates
```

**Force renewal**:
```bash
docker exec caddy caddy renew --force
```

---

## Performance Tuning

### HTTP/3 (QUIC)
Enabled by default in Caddy v2.

### Connection Pooling
Caddy automatically manages connection pooling to backends.

### Recommended Docker Compose Labels
```yaml
services:
  caddy:
    deploy:
      resources:
        limits:
          cpus: '2'
          memory: 512M
        reservations:
          cpus: '0.5'
          memory: 256M
```

---

## Security Best Practices

1. ✅ Always use HTTPS (enforced by Caddy)
2. ✅ Keep Caddy updated (`docker pull caddy:latest`)
3. ✅ Use internal Docker network for backend communication
4. ✅ Don't expose backend ports directly (except Dokploy)
5. ⏳ Add rate limiting (future enhancement)
6. ⏳ Add DDoS protection via Cloudflare (optional)

---

## Monitoring

### Prometheus Metrics (Optional)
Enable metrics in global config:
```caddyfile
{
    servers {
        metrics
    }
}
```

Access at: `http://localhost:2019/metrics`

### Log Analysis
```bash
# Count requests per domain
docker exec caddy sh -c "cat /var/log/caddy/*.log | wc -l"

# Find slow requests (>1s)
docker exec caddy grep -E "took [0-9]{4,}ms" /var/log/caddy/*.log
```

---

## Related Documentation

- [Network Inventory](./NETWORK-INVENTORY.md)
- [Deployment Guide](../DEPLOYMENT-GUIDE.md)
- [Services Overview](../SERVICES.md)

---

## Backup Configuration

Always backup your Caddyfile before changes:
```bash
cp /root/Caddyfile /root/Caddyfile.backup.$(date +%Y%m%d-%H%M%S)
```

Restore if needed:
```bash
cp /root/Caddyfile.backup.YYYYMMDD-HHMMSS /root/Caddyfile
docker exec caddy caddy reload --config /etc/caddy/Caddyfile
```
