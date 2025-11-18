# DeepCode Integration with SmarterOS
# mkt.smarterbot.cl + Nexa Runtime

## 📋 Overview

DeepCode se convierte en el frontal de marketing que consume Nexa Runtime, Shopify y todo el backend de SmarterOS.

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                  mkt.smarterbot.cl                          │
│                  (DeepCode / Next.js)                       │
│                                                             │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐    │
│  │   Landing    │  │  Prompt      │  │  Analytics   │    │
│  │   Pages      │  │  Editor      │  │  Dashboard   │    │
│  └──────────────┘  └──────────────┘  └──────────────┘    │
│                                                             │
│  Authentication: Clerk (multi-tenant)                      │
│  Rendering: Static + ISR                                   │
└─────────────────────────────────────────────────────────────┘
                          │
                          ├──────────────────┬─────────────────┐
                          ▼                  ▼                 ▼
         ┌────────────────────────┐  ┌──────────────┐  ┌───────────────┐
         │  Nexa Runtime          │  │  Supabase    │  │  Shopify API  │
         │  ai.smarterbot.store   │  │  (Config)    │  │  (Webhooks)   │
         └────────────────────────┘  └──────────────┘  └───────────────┘
```

## 🔧 Environment Variables

```bash
# .env.local for DeepCode
NEXT_PUBLIC_APP_URL=https://mkt.smarterbot.cl

# Nexa Runtime
NEXT_PUBLIC_NEXA_API_URL=https://ai.smarterbot.store/v1
NEXT_PUBLIC_NEXA_HEALTH_URL=https://ai.smarterbot.store/health

# MCP Server
NEXT_PUBLIC_MCP_URL=http://localhost:3001

# Supabase
NEXT_PUBLIC_SUPABASE_URL=https://your-project.supabase.co
NEXT_PUBLIC_SUPABASE_ANON_KEY=eyJ...
SUPABASE_SERVICE_ROLE_KEY=eyJ... # Server-side only

# Clerk Authentication
NEXT_PUBLIC_CLERK_PUBLISHABLE_KEY=pk_test_...
CLERK_SECRET_KEY=sk_test_...
NEXT_PUBLIC_CLERK_SIGN_IN_URL=/sign-in
NEXT_PUBLIC_CLERK_SIGN_UP_URL=/sign-up
NEXT_PUBLIC_CLERK_AFTER_SIGN_IN_URL=/dashboard
NEXT_PUBLIC_CLERK_AFTER_SIGN_UP_URL=/onboarding

# Shopify (per tenant in Vault)
# Not exposed in client
SHOPIFY_API_KEY=... # Server-side only
SHOPIFY_API_SECRET=... # Server-side only
```

## 📁 Project Structure

```
mkt.smarterbot.cl/
├── app/
│   ├── (marketing)/
│   │   ├── page.tsx              # Landing page
│   │   ├── features/page.tsx
│   │   └── pricing/page.tsx
│   ├── (dashboard)/
│   │   ├── dashboard/
│   │   │   ├── page.tsx          # Analytics
│   │   │   ├── prompts/          # Prompt editor
│   │   │   └── stores/           # Shopify stores
│   │   └── layout.tsx            # Authenticated layout
│   └── api/
│       ├── nexa/
│       │   ├── chat/route.ts     # Proxy to Nexa Runtime
│       │   └── health/route.ts
│       ├── shopify/
│       │   ├── webhooks/route.ts
│       │   └── prompts/route.ts
│       └── analytics/route.ts
├── components/
│   ├── ai/
│   │   ├── chat-interface.tsx
│   │   ├── prompt-editor.tsx
│   │   └── model-selector.tsx
│   ├── shopify/
│   │   ├── store-selector.tsx
│   │   └── prompt-manager.tsx
│   └── analytics/
│       ├── metrics-card.tsx
│       └── usage-chart.tsx
├── lib/
│   ├── nexa-client.ts           # Nexa Runtime API client
│   ├── supabase.ts              # Supabase client
│   ├── clerk.ts                 # Clerk auth helpers
│   └── shopify.ts               # Shopify API helpers
└── hooks/
    ├── use-nexa.ts
    ├── use-tenant.ts
    └── use-shopify-prompts.ts
```

## 💻 Nexa Client Implementation

### lib/nexa-client.ts

```typescript
import { auth } from '@clerk/nextjs';

interface NexaMessage {
  role: 'system' | 'user' | 'assistant';
  content: string;
}

interface NexaChatRequest {
  model?: string;
  messages: NexaMessage[];
  temperature?: number;
  max_tokens?: number;
}

interface NexaChatResponse {
  id: string;
  object: string;
  created: number;
  model: string;
  choices: Array<{
    index: number;
    message: NexaMessage;
    finish_reason: string;
  }>;
  usage: {
    prompt_tokens: number;
    completion_tokens: number;
    total_tokens: number;
  };
}

export class NexaClient {
  private baseUrl: string;
  private tenantId: string;

  constructor(tenantId: string) {
    this.baseUrl = process.env.NEXT_PUBLIC_NEXA_API_URL || 'https://ai.smarterbot.store/v1';
    this.tenantId = tenantId;
  }

  async chat(request: NexaChatRequest): Promise<NexaChatResponse> {
    const response = await fetch(`${this.baseUrl}/chat/completions`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'X-Tenant-Id': this.tenantId,
      },
      body: JSON.stringify({
        model: request.model || 'llama-3-8b-instruct',
        messages: request.messages,
        temperature: request.temperature || 0.7,
        max_tokens: request.max_tokens || 1024,
      }),
    });

    if (!response.ok) {
      throw new Error(`Nexa API error: ${response.statusText}`);
    }

    return response.json();
  }

  async health(): Promise<{ status: string; service: string }> {
    const response = await fetch(`${this.baseUrl.replace('/v1', '')}/health`);
    return response.json();
  }
}

// Hook for React components
export function useNexa() {
  const { userId, orgId } = auth();
  const tenantId = orgId || userId || 'demo';

  return new NexaClient(tenantId);
}
```

### components/ai/chat-interface.tsx

```typescript
'use client';

import { useState } from 'react';
import { useNexa } from '@/lib/nexa-client';

export function ChatInterface() {
  const [messages, setMessages] = useState<Array<{ role: string; content: string }>>([]);
  const [input, setInput] = useState('');
  const [loading, setLoading] = useState(false);
  const nexa = useNexa();

  const handleSend = async () => {
    if (!input.trim()) return;

    const userMessage = { role: 'user' as const, content: input };
    setMessages(prev => [...prev, userMessage]);
    setInput('');
    setLoading(true);

    try {
      const response = await nexa.chat({
        messages: [...messages, userMessage],
      });

      const assistantMessage = response.choices[0].message;
      setMessages(prev => [...prev, assistantMessage]);
    } catch (error) {
      console.error('Nexa error:', error);
      // Show error toast
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="flex flex-col h-full">
      <div className="flex-1 overflow-y-auto p-4 space-y-4">
        {messages.map((msg, idx) => (
          <div
            key={idx}
            className={`flex ${msg.role === 'user' ? 'justify-end' : 'justify-start'}`}
          >
            <div
              className={`max-w-[80%] rounded-lg px-4 py-2 ${
                msg.role === 'user'
                  ? 'bg-blue-500 text-white'
                  : 'bg-gray-200 text-gray-900'
              }`}
            >
              {msg.content}
            </div>
          </div>
        ))}
        {loading && (
          <div className="flex justify-start">
            <div className="bg-gray-200 rounded-lg px-4 py-2">
              <span className="animate-pulse">Pensando...</span>
            </div>
          </div>
        )}
      </div>
      <div className="border-t p-4">
        <div className="flex gap-2">
          <input
            type="text"
            value={input}
            onChange={(e) => setInput(e.target.value)}
            onKeyPress={(e) => e.key === 'Enter' && handleSend()}
            placeholder="Escribe tu mensaje..."
            className="flex-1 px-4 py-2 border rounded-lg"
            disabled={loading}
          />
          <button
            onClick={handleSend}
            disabled={loading}
            className="px-6 py-2 bg-blue-500 text-white rounded-lg hover:bg-blue-600 disabled:opacity-50"
          >
            Enviar
          </button>
        </div>
      </div>
    </div>
  );
}
```

## 🔐 Authentication with Clerk

### app/layout.tsx

```typescript
import { ClerkProvider } from '@clerk/nextjs';

export default function RootLayout({ children }: { children: React.Node }) {
  return (
    <ClerkProvider>
      <html lang="es">
        <body>{children}</body>
      </html>
    </ClerkProvider>
  );
}
```

### Multi-tenant via Organizations

```typescript
import { auth, currentUser } from '@clerk/nextjs';

export async function getTenantId(): Promise<string> {
  const { userId, orgId } = auth();
  
  // Use organization ID as tenant ID if available
  if (orgId) {
    return orgId;
  }
  
  // Fallback to user ID
  if (userId) {
    return userId;
  }
  
  return 'demo';
}
```

## 🛍️ Shopify Integration

### hooks/use-shopify-prompts.ts

```typescript
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { createClient } from '@/lib/supabase';

export function useShopifyPrompts(tenantId: string) {
  const supabase = createClient();
  const queryClient = useQueryClient();

  const { data: prompts, isLoading } = useQuery({
    queryKey: ['shopify-prompts', tenantId],
    queryFn: async () => {
      const { data, error } = await supabase
        .from('shopify_tenant_prompts')
        .select('*')
        .eq('tenant_id', tenantId)
        .eq('active', true);

      if (error) throw error;
      return data;
    },
  });

  const updatePrompt = useMutation({
    mutationFn: async (prompt: {
      shop_domain: string;
      system_prompt: string;
      model_config: object;
    }) => {
      const { data, error } = await supabase
        .from('shopify_tenant_prompts')
        .upsert({
          tenant_id: tenantId,
          ...prompt,
        })
        .select();

      if (error) throw error;
      return data;
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['shopify-prompts', tenantId] });
    },
  });

  return { prompts, isLoading, updatePrompt };
}
```

## 📊 Analytics Dashboard

### app/(dashboard)/dashboard/page.tsx

```typescript
import { auth } from '@clerk/nextjs';
import { MetricsCard } from '@/components/analytics/metrics-card';
import { UsageChart } from '@/components/analytics/usage-chart';
import { getTenantId } from '@/lib/tenant';

export default async function DashboardPage() {
  const tenantId = await getTenantId();

  return (
    <div className="space-y-8">
      <h1 className="text-3xl font-bold">Dashboard</h1>
      
      <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
        <MetricsCard
          title="Total Requests (24h)"
          tenantId={tenantId}
          metric="requests_24h"
        />
        <MetricsCard
          title="Tokens Used"
          tenantId={tenantId}
          metric="tokens_total"
        />
        <MetricsCard
          title="Avg Latency"
          tenantId={tenantId}
          metric="latency_avg"
        />
      </div>

      <UsageChart tenantId={tenantId} />
    </div>
  );
}
```

## 🚀 Deployment

### Vercel Configuration

```json
{
  "buildCommand": "next build",
  "devCommand": "next dev",
  "installCommand": "npm install",
  "framework": "nextjs",
  "outputDirectory": ".next",
  "env": {
    "NEXT_PUBLIC_NEXA_API_URL": "https://ai.smarterbot.store/v1",
    "NEXT_PUBLIC_SUPABASE_URL": "@supabase-url",
    "NEXT_PUBLIC_SUPABASE_ANON_KEY": "@supabase-anon-key"
  }
}
```

### Deploy Script

```bash
#!/bin/bash
# deploy-deepcode.sh

# Build
npm run build

# Deploy to Vercel
vercel --prod

# Or deploy to custom domain
rsync -av .next/ user@mkt.smarterbot.cl:/var/www/deepcode/
```

## ✅ Integration Checklist

- [ ] Environment variables configured
- [ ] Clerk authentication setup
- [ ] Nexa client implemented
- [ ] Supabase connection tested
- [ ] Shopify webhooks configured
- [ ] Analytics dashboard created
- [ ] Prompt editor functional
- [ ] Multi-tenant isolation verified
- [ ] SSL certificate configured
- [ ] DNS pointing to mkt.smarterbot.cl

## 📚 API Routes

```
GET  /api/nexa/health          → Nexa health check
POST /api/nexa/chat            → Chat with Nexa (proxied)
GET  /api/shopify/prompts      → Get tenant prompts
POST /api/shopify/prompts      → Update prompts
POST /api/shopify/webhooks     → Shopify webhook handler
GET  /api/analytics/metrics    → Tenant metrics
```

---

**Status:** Ready for implementation
**Version:** 1.0.0
**Last Updated:** 2025-11-18T20:24:38.275Z
