---
title: Catálogo MCP
version: 1.1
updated: 2025-11-22
description: Inventario y arquitectura de recursos MCP publicados en https://mcp.smarterbot.cl/
---

# Catálogo MCP (SmarterBOT)

## 1. Visión General
Este documento organiza los recursos MCP disponibles y la estrategia para exponerlos vía `https://mcp.smarterbot.cl/` como catálogo consultable por clientes (navegador, agentes MCP y automaciones internas).

## 2. Repositorios Fuente
- **n8n-workflows** · https://github.com/Zie619/n8n-workflows  
  Colección pública base para flujos reutilizables (referenciada para inspiración / forks).
- (Próximo) **smarterbot-n8n-flows** · Repositorio privado propio con versionado semántico y etiquetas de despliegue.

## 3. Taxonomía de Flujos
Cada flujo se clasifica por: `categoria`, `integraciones`, `nivel` (core, opcional), `tags` libres y `estado` (stable, beta, deprecated).

| Categoría | Propósito | Ejemplos (archivo) | Tags sugeridos |
|-----------|-----------|--------------------|----------------|
| BlogBowl | Publicación y métricas de contenido | `blogbowl-publish-post.yml`, `blogbowl-fetch-stats.yml` | `content,seo,metrics` |
| Meta Ads | Creación y monitoreo de campañas | `meta-create-campaign.yml`, `meta-fetch-stats.yml` | `ads,facebook,marketing` |
| Odoo | ERP: pedidos, inventario, facturación | `odoo-create-order.yml`, `odoo-sync-stock.yml` | `erp,orders,inventory` |
| Shopify | E‑commerce: productos y clientes | `shopify-new-product.yml`, `shopify-sync-customers.yml` | `ecommerce,products,customers` |
| Odoo + Meta Ads | Atribución y sincronización de ventas | `odoo-to-meta-sync.yml` | `erp,ads,attribution` |
| Shopify + Meta Ads | Generación automática de anuncios | `shopify-to-meta-ad.yml` | `ecommerce,ads,automation` |

## 4. Modelo de Datos (Índice de Búsqueda)
Documento base para cada flujo indexado:
```jsonc
{
  "id": "odoo-create-order",
  "categoria": "Odoo",
  "descripcion": "Crea pedidos automáticamente desde fuente externa.",
  "archivo": "odoo-create-order.yml",
  "repo": "smarterbot-n8n-flows",
  "tags": ["erp", "orders"],
  "nivel": "core",
  "estado": "stable",
  "integraciones": ["odoo", "supabase"],
  "ultima_actualizacion": "2025-11-22",
  "variables_entorno": ["ODOO_API_KEY", "SUPABASE_URL"],
  "compose_template": "docker/odoo-create-order.compose.yml"
}
```

## 5. Arquitectura de Búsqueda MCP
1. **Indexador**: Job (cron / n8n) que parsea repos y genera documentos normalizados (JSON) → almacén (Meilisearch recomendado por simplicidad y relevancia).
2. **Servicio `/mcp/search`**: Endpoint FastAPI expone consulta paramétrica (`q`, `categoria`, `tag`, `estado`, `nivel`).
3. **Respuesta**: Lista paginada + facets (conteo por categoría / estado) para UI y agentes.
4. **Cache**: TTL corto (30–120s) con revalidación condicional en flujos de alta rotación.

## 6. Endpoints Planeados
| Endpoint | Método | Parámetros | Descripción |
|----------|--------|------------|-------------|
| `/mcp/search` | GET | `q, categoria, tag, page, size` | Búsqueda textual + filtros |
| `/mcp/flow/{id}` | GET | `expand=vars|compose` | Detalle de flujo |
| `/mcp/categories` | GET | — | Listado y métricas por categoría |
| `/mcp/tags` | GET | — | Cloud de tags frecuentes |
| `/mcp/random` | GET | `categoria?` | Flujo aleatorio (inspiración) |

## 7. Integración con SmarterBOT.store
- **Marketplace interno**: UI permite activar/duplicar flujos con validación de variables requeridas.
- **Dokploy**: Plantilla `docker-compose.yml` por flujo; acción de despliegue crea stack aislado.
- **Observabilidad**: Cada contenedor n8n expone métricas (Prometheus) y logs centralizados (Loki).
- **Seguridad**: Variables sensibles gestionadas en Vault; sincronización automática al crear el stack.

## 8. Roadmap (Prioridades)
| Fase | Objetivo | Resultado |
|------|----------|-----------|
| 1 | Indexador + Meilisearch | Base de búsqueda funcional |
| 2 | Endpoint `/mcp/search` | API abierta a UI / agentes |
| 3 | UI Marketplace | Selección y filtrado usable |
| 4 | Deploy automatizado Dokploy | Activación 1‑click |
| 5 | Documentación ampliada | Fichas completas por flujo |
| 6 | Métricas + monitoreo | Panel operativo |

## 9. Buenas Prácticas de Flujos
- Prefijo consistente en IDs (`odoo-`, `shopify-`, `meta-`, `blogbowl-`).
- Versión en comentario inicial del YAML (`# version: 1.0.0`).
- Lista clara de variables de entorno requeridas y opcionales.
- Evitar credenciales incrustadas; siempre referenciar variables.
- Documentar dependencias externas (APIs, webhooks) y límites.

## 10. Glosario Rápido
- **nivel**: Importancia estratégica (core/optional).
- **estado**: Ciclo de vida (stable/beta/deprecated).
- **integraciones**: Sistemas conectados por el flujo.
- **compose_template**: Archivo base para despliegue containerizado.

---
*Este catálogo reorganizado sirve como referencia operativa para la evolución de la plataforma MCP y su exposición en `mcp.smarterbot.cl`.*
