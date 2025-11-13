# BRAND-STORY – Identidad y Lineamientos de SmarterOS

## 1. Narrativa y Tono de Marca (Fuente Oficial)

La historia, el ADN y el posicionamiento de SmarterBot están publicados en:

👉 **https://www.smarterbot.cl/**

Esta es la **fuente oficial** de la narrativa y NO SE MODIFICA.

Todo el contenido, tono y comunicación pública se mantiene tal cual está en ese sitio.

---

## 2. Experiencia Visual de la App Principal

La app principal:

👉 **https://app.smarterbot.cl/**

Se mantiene **EXACTAMENTE como está hoy.**

- Cockpit moderno para founders
- Diseño limpio, claro y neutral
- No se cambia el look & feel actual

---

## 3. Login Unificado del Ecosistema

Todos los logins del ecosistema SmarterOS (excepto app.smarterbot.cl) deben seguir el estilo de:

👉 **https://odoo.smarterbot.cl/**

### Características del login estándar:

✔ **Look & feel:**
- Fondo corporativo
- Tipografía consistente
- Inputs del mismo tamaño y estilo
- Colores de marca
- Botón de login unificado
- Layout simple centrado
- Modo "empresa"

✔ **Flujo:**
- Email
- Password
- Control básico
- Entrada hacia cada servicio
- Multi-tenant adaptable

### Servicios que usan este login:

- Odoo (ERP)
- n8n (Automatización)
- Metabase (Analítica)
- Chatwoot (Soporte)
- Botpress (Chatbots)
- Cualquier nuevo servicio del ecosistema

---

## 4. Reglas de Consistencia

| Elemento | Regla |
|----------|-------|
| **Narrativa pública** | Se respeta www.smarterbot.cl como fuente oficial |
| **App principal** | app.smarterbot.cl NO se modifica |
| **Logins de servicios** | Replican el estilo de odoo.smarterbot.cl |
| **Tono de comunicación** | Profesional, claro, orientado a founders |
| **Identidad visual** | Corporativa, confiable, moderna |

---

## 5. Orígenes

SmarterBot nace de la necesidad de automatizar negocios digitales con herramientas empresariales de nivel mundial, pero accesibles y multi-tenant.

El fundador identifica la brecha entre herramientas complejas (SAP, Oracle) y herramientas simples (Shopify, WooCommerce), y crea un OS que combina:

- ERP robusto (Odoo)
- Comercio moderno (Shopify)
- Automatización inteligente (n8n)
- Analítica profesional (Metabase)
- AI como copiloto (Smarterbot)

Todo operando en ciclos diarios, con arquitectura multi-tenant y control total desde WhatsApp.

---

## 6. Implementación

Ver:
- `specs/login.yml` – Especificaciones técnicas del login unificado
- `/design/login-theme/` – Assets y estilos CSS
- `/templates/login/` – Templates listos para cada servicio
