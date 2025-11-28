# 🧠 Core Graph — Arquitectura Tri-Agente SmarterOS

**Versión**: 1.0  
**Fecha**: 2025-11-16  
**Sistema**: Multi-modelo orquestado con 25 MCP + Vault + GitHub Actions

---

## 📊 Diagrama de Flujo Principal

```
┌─────────────────────────────────────────────────────────────────────────┐
│                         🎯 GEMINI (DIRECTOR)                            │
│                                                                         │
│  • Analiza contexto global (specs, issues, logs)                       │
│  • Divide tareas en pasos atómicos                                     │
│  • Identifica archivos/servicios a modificar                           │
│  • Genera plan de ejecución                                            │
│  • Valida dependencias y orden                                         │
│                                                                         │
│  MCP consumidos: shopify, supabase, metabase, slack, notion,          │
│                  google, odoo, n8n, openai, anthropic                 │
└────────────────────────────┬────────────────────────────────────────────┘
                             │ Plan JSON
                             │ {tasks: [...], files: [...], order: [...]}
                             ▼
┌─────────────────────────────────────────────────────────────────────────┐
│                      ✍️  COPILOT (WRITER)                               │
│                                                                         │
│  • Recibe plan de Gemini                                               │
│  • Genera código real (TypeScript, Python, YAML, SQL)                 │
│  • Mantiene estilo y convenciones del repo                            │
│  • Produce tests y validaciones                                        │
│  • Optimiza performance y estructura                                   │
│                                                                         │
│  MCP consumidos: github, context7, repo-analysis                       │
│  Workspace: smarteros-specs/, app.smarterbot.cl/, smarterbot.cl/      │
└────────────────────────────┬────────────────────────────────────────────┘
                             │ Code patches
                             │ [{file, oldContent, newContent}, ...]
                             ▼
┌─────────────────────────────────────────────────────────────────────────┐
│                      🛠️  CODEX CLI (EXECUTOR)                           │
│                                                                         │
│  • Aplica patches generados por Copilot                                │
│  • Ejecuta builds (pnpm build, docker build)                           │
│  • Sincroniza con VPS (rsync via ssh smarteros)                        │
│  • Reinicia servicios (systemctl, docker compose)                      │
│  • Ejecuta validaciones (tests, health checks)                         │
│  • Reporta resultados a Gemini                                         │
│                                                                         │
│  MCP consumidos: docker, ssh, vault, hostinger, caddy                  │
│  Comandos: sync-smarteros.sh, master-setup.sh, systemctl              │
└────────────────────────────┬────────────────────────────────────────────┘
                             │ Results + Logs
                             │ {success, errors, metrics}
                             ▼
┌─────────────────────────────────────────────────────────────────────────┐
│                      🔄 FEEDBACK LOOP                                   │
│                                                                         │
│  • Gemini analiza resultados                                           │
│  • Si hay errores → genera nuevo plan (retry/fix)                      │
│  • Si success → marca tarea completa                                   │
│  • Actualiza memoria en Vault + GitHub Issues                          │
│  • Notifica en Slack/Linear si configurado                             │
└─────────────────────────────────────────────────────────────────────────┘
```

---

## 🔀 Flujo por Tipo de Tarea

### A) Feature Nueva (Issue → Deploy)

```
1. GitHub Issue creado
   ↓
2. GEMINI analiza issue + specs + codebase
   → genera plan: [crear componente, añadir route, update DB schema]
   ↓
3. COPILOT genera código para cada paso
   → components/new-feature.tsx
   → app/api/new-endpoint/route.ts
   → supabase migration SQL
   ↓
4. CODEX ejecuta:
   → aplica patches
   → corre migrations (supabase)
   → build Next.js
   → sync a VPS
   → restart app
   ↓
5. GEMINI valida:
   → health check OK?
   → logs sin errores?
   → feature visible en producción?
   ↓
6. Si OK → cierra issue con comentario detallado
   Si FAIL → genera plan de rollback/fix
```

### B) Bug Fix (Error → Patch)

```
1. Error detectado (logs, Sentry, usuario)
   ↓
2. GEMINI analiza:
   → stack trace
   → archivos relacionados
   → cambios recientes (git blame)
   → hipótesis de causa raíz
   ↓
3. COPILOT genera fix:
   → patch específico
   → test que reproduce el bug
   → validación adicional
   ↓
4. CODEX ejecuta:
   → aplica fix
   → corre tests
   → deploy si tests pasan
   ↓
5. GEMINI verifica:
   → error ya no ocurre?
   → side effects?
   → documentar causa en issue
```

### C) Refactor (Tech Debt → Mejora)

```
1. GEMINI identifica deuda técnica:
   → código duplicado
   → dependencias obsoletas
   → patrones anti-pattern
   ↓
2. GEMINI propone plan de refactor:
   → prioriza por impacto/riesgo
   → divide en PRs pequeños
   → define criterios de éxito
   ↓
3. COPILOT refactoriza incremental:
   → extrae funciones comunes
   → actualiza imports
   → migra APIs deprecated
   ↓
4. CODEX valida:
   → tests siguen pasando
   → build exitoso
   → performance igual o mejor
   ↓
5. GEMINI documenta:
   → changelog
   → ADR (Architecture Decision Record)
   → actualiza specs
```

---

## 🔌 Integración con MCP (25 proveedores)

### MCP Tier 1 — Core (siempre activos)

| MCP | Agente principal | Uso |
|-----|------------------|-----|
| github | Copilot, Gemini | repos, issues, PRs, releases |
| vault | Codex | secretos, tokens, keys |
| docker | Codex | containers, builds, compose |
| hostinger | Codex | VPS, DNS, SSH |
| supabase | Gemini, Codex | auth, DB, storage |

### MCP Tier 2 — Business Logic

| MCP | Agente principal | Uso |
|-----|------------------|-----|
| shopify | Gemini | storefront, productos, órdenes |
| metabase | Gemini | analytics, dashboards, queries |
| odoo | Gemini | ERP, CRM, facturación |
| stripe | Gemini, Codex | pagos, suscripciones |
| n8n | Gemini | workflows, automatizaciones |

### MCP Tier 3 — AI/ML

| MCP | Agente principal | Uso |
|-----|------------------|-----|
| openai | Gemini | GPT-4, embeddings, vision |
| anthropic | Gemini | Claude, análisis complejo |
| google | Gemini | Gemini API, Cloud services |
| context7 | Copilot | docs, code examples |

### MCP Tier 4 — Comunicación

| MCP | Agente principal | Uso |
|-----|------------------|-----|
| slack | Gemini | notificaciones, alertas |
| twilio | Gemini | SMS, llamadas |
| whatsapp | Gemini | mensajes, business API |
| mailgun | Gemini | emails transaccionales |

### MCP Tier 5 — DevOps/Infra

| MCP | Agente principal | Uso |
|-----|------------------|-----|
| cloudflare | Codex | DNS, WAF, CDN |
| aws | Codex | S3, Lambda, EC2 (si aplica) |
| caddy | Codex | reverse proxy, SSL |
| linear | Gemini | project mgmt, roadmap |
| notion | Gemini | docs, wikis, knowledge base |

---

## 📦 Memoria Persistente

### Vault (Secretos + Estado)

```
smarteros/
├── ssh/deploy          # Claves SSH
├── app/production      # Env vars producción
├── mcp/                # 25 MCP credentials
│   ├── hostinger
│   ├── github
│   ├── shopify
│   └── ...
└── agents/             # Estado de agentes
    ├── gemini-context  # Último plan, decisiones
    ├── copilot-style   # Guías de estilo, patterns
    └── codex-state     # Últimos comandos, logs
```

### GitHub (Código + Historia)

```
app.smarterbot.cl/
├── .github/workflows/  # CI/CD tri-agente
├── smarteros-specs/    # Fuente de verdad
└── CHANGELOG.md        # Generado automático
```

### Specs (Intención + Contratos)

```
smarteros-specs/
├── agents/             # Specs de agentes
│   ├── director-gemini.yml
│   ├── writer-copilot.yml
│   └── executor-codex.yml
├── orchestrator.yml    # Flujo maestro
└── mcp-registry.yml    # Mapeo de MCPs a agentes
```

---

## 🚀 Triggers de Orquestación

### Trigger 1: Git Push

```
push → main
  ↓
GitHub Actions
  ↓
Gemini analiza diff
  ↓
decide si requiere:
  • build + deploy (Copilot + Codex)
  • solo sync specs (Codex)
  • nada (commit docs-only)
```

### Trigger 2: GitHub Issue

```
new issue con label:auto
  ↓
Gemini analiza
  ↓
crea plan
  ↓
Copilot genera código
  ↓
Codex ejecuta
  ↓
Gemini comenta en issue con resultado
```

### Trigger 3: Cron / Scheduled

```
daily 02:00 UTC
  ↓
Gemini revisa:
  • dependencias desactualizadas
  • logs con errores recurrentes
  • métricas de performance
  ↓
propone mejoras automáticas
  ↓
si aprobado → Copilot + Codex ejecutan
```

### Trigger 4: Manual (CLI)

```
$ ./orchestrate.sh "optimize database queries"
  ↓
Gemini recibe prompt
  ↓
genera plan
  ↓
Copilot + Codex ejecutan
  ↓
reporte en terminal
```

---

## 🎯 Métricas de Éxito

### KPIs del Sistema Tri-Agente

| Métrica | Target | Actual |
|---------|--------|--------|
| Time to deploy (commit → producción) | < 5 min | - |
| Auto-fix rate (bugs resueltos sin humano) | > 60% | - |
| Test coverage (generado automático) | > 80% | - |
| Specs sync (specs ↔ código coherente) | 100% | - |
| MCP uptime (disponibilidad de conectores) | > 99% | - |
| Agent coordination errors | < 1% | - |

### Logs y Observabilidad

```
/var/log/smarteros/
├── gemini-decisions.log    # Planes y razonamientos
├── copilot-generations.log # Código generado
├── codex-executions.log    # Comandos ejecutados
└── orchestrator.log        # Flujo completo
```

---

## 🔐 Seguridad y Permisos

### Gemini (Director)
- **Puede**: leer todo, analizar, proponer
- **No puede**: modificar archivos directamente, ejecutar comandos

### Copilot (Writer)
- **Puede**: generar código, sugerir patches
- **No puede**: aplicar cambios sin aprobación de Codex

### Codex (Executor)
- **Puede**: aplicar patches aprobados, ejecutar comandos whitelisted
- **No puede**: modificar secrets en Vault, acceso root directo

### Checklist de Seguridad
- ✅ Todos los secretos en Vault (nunca en código)
- ✅ Comandos Codex restringidos por sudoers
- ✅ SSH solo con keys (no passwords)
- ✅ Logs auditables de todas las acciones
- ✅ Rollback automático si falla validación

---

## 🧪 Testing del Sistema

### Test 1: Feature End-to-End
```bash
# Crear issue con label:auto
gh issue create --title "Add dark mode toggle" --label auto

# Observar logs tri-agente
tail -f /var/log/smarteros/orchestrator.log

# Verificar deploy automático
curl https://app.smarterbot.cl | grep "dark-mode"
```

### Test 2: Bug Fix Automático
```bash
# Simular error
echo "throw new Error('test')" >> app/api/test/route.ts
git add . && git commit -m "test: trigger auto-fix" && git push

# Gemini debe detectar, Copilot fix, Codex deploy
```

### Test 3: Refactor Programado
```bash
# Trigger manual
./orchestrate.sh "refactor: extract common auth logic"

# Revisar PR generado automáticamente
gh pr list --label bot
```

---

## 📚 Recursos Adicionales

- [Specs Director Gemini](./director-gemini.yml)
- [Specs Writer Copilot](./writer-copilot.yml)
- [Specs Executor Codex](./executor-codex.yml)
- [Orchestrator Config](./orchestrator.yml)
- [MCP Registry](./mcp-registry.yml)

---

**Construido con ❤️ por SmarterCL**  
**Powered by**: Gemini (Director) · Copilot (Writer) · Codex CLI (Executor) · 25 MCP · Vault OSS
