# 🔐 VAULT TENANT LAYOUT

**Version**: 1.0.0  
**Purpose**: Definir estructura de secretos en Vault por RUT para SmarterOS  
**Date**: 2025-11-23

---

## 📋 ESTRUCTURA BASE

Todos los secretos de tenant se organizan bajo el path:

```
secret/data/tenant/<RUT>/
```

Donde `<RUT>` es el RUT chileno con formato: `12345678-9`

---

## 🗂️ LAYOUT POR SERVICIO

### 1. Shopify

**Path**: `secret/data/tenant/<RUT>/shopify`

**Estructura**:
```json
{
  "data": {
    "shop_domain": "demo-smarter.myshopify.com",
    "access_token": "shpat_xxxxxxxxxxxxxxxxxxxxx",
    "webhook_secret": "whsec_xxxxxxxxxxxxxxxx",
    "api_version": "2024-04",
    "scopes": "read_products,write_orders,read_customers"
  }
}
```

**Campos**:
- `shop_domain`: Dominio de la tienda Shopify
- `access_token`: Token OAuth de la app
- `webhook_secret`: Secret para validar webhooks
- `api_version`: Versión de API Shopify
- `scopes`: Permisos OAuth granted

---

### 2. Odoo

**Path**: `secret/data/tenant/<RUT>/odoo`

**Estructura**:
```json
{
  "data": {
    "base_url": "https://odoo.smarterbot.cl",
    "db": "tenant_76958020_3",
    "username": "api_user",
    "password": "super-secret-password",
    "company_id": 1,
    "api_key": "odoo_api_key_xxxx"
  }
}
```

**Campos**:
- `base_url`: URL base de la instancia Odoo
- `db`: Nombre de la base de datos del tenant
- `username`: Usuario API
- `password`: Contraseña del usuario API
- `company_id`: ID de la compañía en Odoo
- `api_key`: API key (si se usa autenticación por key)

---

### 3. Chatwoot

**Path**: `secret/data/tenant/<RUT>/chatwoot`

**Estructura**:
```json
{
  "data": {
    "base_url": "https://chat.smarterbot.cl",
    "account_id": 3,
    "inbox_id": 12,
    "api_access_token": "cwpat_xxxxxxxxxxxxxxxx",
    "agent_bot_id": 5
  }
}
```

**Campos**:
- `base_url`: URL de la instancia Chatwoot
- `account_id`: ID de la cuenta del tenant
- `inbox_id`: ID del inbox principal
- `api_access_token`: Token de API
- `agent_bot_id`: ID del bot agent (opcional)

---

### 4. n8n

**Path**: `secret/data/tenant/<RUT>/n8n`

**Estructura**:
```json
{
  "data": {
    "base_url": "https://n8n.smarterbot.cl",
    "api_key": "n8n_api_key_xxxxxxxx",
    "workflow_ids": {
      "shopify_to_odoo": "workflow_123",
      "post_sale_followup": "workflow_456",
      "inventory_sync": "workflow_789"
    }
  }
}
```

**Campos**:
- `base_url`: URL de la instancia n8n
- `api_key`: API key para ejecutar workflows
- `workflow_ids`: Map de workflows por función

---

### 5. Certificados SII (Chile)

**Path**: `secret/data/tenant/<RUT>/sii`

**Estructura**:
```json
{
  "data": {
    "cert_pem": "-----BEGIN CERTIFICATE-----\n...",
    "key_pem": "-----BEGIN PRIVATE KEY-----\n...",
    "rut_emisor": "76958020-3",
    "ambiente": "certificacion",
    "caf_folios": {
      "33": {
        "desde": 1,
        "hasta": 1000,
        "caf_xml": "<CAF>...</CAF>"
      }
    }
  }
}
```

**Campos**:
- `cert_pem`: Certificado digital PEM
- `key_pem`: Llave privada PEM
- `rut_emisor`: RUT del emisor
- `ambiente`: `certificacion` o `produccion`
- `caf_folios`: CAF (Código de Autorización de Folios) por tipo DTE

---

## 🔄 OPERACIONES VAULT

### Lectura de secreto

```python
import hvac

client = hvac.Client(url='http://vault:8200', token='vault-token')

# Leer secreto de Shopify
secret = client.secrets.kv.v2.read_secret_version(
    path='tenant/76958020-3/shopify'
)

shop_domain = secret['data']['data']['shop_domain']
access_token = secret['data']['data']['access_token']
```

### Escritura de secreto

```python
# Guardar secreto de Odoo
client.secrets.kv.v2.create_or_update_secret(
    path='tenant/76958020-3/odoo',
    secret={
        'base_url': 'https://odoo.smarterbot.cl',
        'db': 'tenant_76958020_3',
        'username': 'api_user',
        'password': 'secure-pass'
    }
)
```

### Inicializar paths de tenant

```python
def init_tenant_vault_paths(rut: str):
    """Initialize all Vault paths for a new tenant"""
    services = ['shopify', 'odoo', 'chatwoot', 'n8n', 'sii']
    
    for service in services:
        path = f'tenant/{rut}/{service}'
        # Create empty secret (will be filled during service connection)
        client.secrets.kv.v2.create_or_update_secret(
            path=path,
            secret={'initialized': True, 'connected': False}
        )
```

---

## 🔒 POLÍTICAS DE ACCESO

### Policy para MCP Server

```hcl
# policy: mcp-server-tenant-access
path "secret/data/tenant/*" {
  capabilities = ["create", "read", "update", "delete", "list"]
}

path "secret/metadata/tenant/*" {
  capabilities = ["list", "read"]
}
```

### Policy por servicio (read-only)

```hcl
# policy: shopify-integration-readonly
path "secret/data/tenant/*/shopify" {
  capabilities = ["read"]
}
```

---

## 📊 JERARQUÍA COMPLETA

```
secret/
└── data/
    └── tenant/
        ├── 76958020-3/
        │   ├── shopify
        │   ├── odoo
        │   ├── chatwoot
        │   ├── n8n
        │   └── sii
        ├── 12345678-9/
        │   ├── shopify
        │   ├── odoo
        │   ├── chatwoot
        │   ├── n8n
        │   └── sii
        └── ...
```

---

## 🚀 BOOTSTRAP DE TENANT

Cuando un tenant nuevo se registra (onboarding), el MCP Server debe:

1. **Validar RUT**: Verificar formato y dígito verificador
2. **Crear tenant en Supabase**: Insertar en tabla `tenants`
3. **Inicializar Vault paths**: Crear estructura `secret/data/tenant/<RUT>/`
4. **Registrar evento**: Log en `tenant_events`

Script de ejemplo:

```python
async def onboard_tenant(rut: str, razon_social: str, email: str):
    # 1. Validar RUT
    if not validate_chilean_rut(rut):
        raise ValueError("RUT inválido")
    
    # 2. Crear en Supabase
    tenant = await supabase.table("tenants").insert({
        "rut": rut,
        "razon_social": razon_social,
        "email_contacto": email
    }).execute()
    
    # 3. Inicializar Vault
    await init_tenant_vault_paths(rut)
    
    # 4. Log evento
    await supabase.rpc("log_tenant_event", {
        "p_tenant_id": tenant.data[0]["id"],
        "p_event_type": "onboard_completed",
        "p_payload": {"rut": rut}
    }).execute()
    
    return tenant.data[0]
```

---

## 🔍 VERIFICACIÓN

Para verificar que un tenant tiene sus paths correctamente inicializados:

```bash
# Listar todos los paths de un tenant
vault kv list secret/tenant/76958020-3/

# Debería retornar:
# Keys
# ----
# chatwoot
# n8n
# odoo
# shopify
# sii
```

---

## 📚 REFERENCIAS

- [Vault KV v2 API](https://developer.hashicorp.com/vault/api-docs/secret/kv/kv-v2)
- [Vault Policies](https://developer.hashicorp.com/vault/docs/concepts/policies)
- [Python hvac client](https://hvac.readthedocs.io/)
