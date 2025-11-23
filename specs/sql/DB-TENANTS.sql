-- ============================================================================
-- SUPABASE SCHEMA - TENANT MANAGEMENT
-- ============================================================================
-- Version: 1.0.0
-- Description: Core tenant tables for SmarterOS multi-tenancy by RUT
-- Author: SmarterOS Team
-- Date: 2025-11-23
-- ============================================================================

-- Enable UUID extension
create extension if not exists "uuid-ossp";

-- ============================================================================
-- 1) TENANTS TABLE - One row per Chilean RUT
-- ============================================================================

create table if not exists tenants (
  id uuid primary key default gen_random_uuid(),
  rut text not null unique,
  razon_social text not null,
  email_contacto text not null,
  telefono_contacto text,
  dominio_principal text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  is_active boolean not null default true,
  
  -- Indexes
  constraint tenants_rut_check check (rut ~ '^\d{7,8}-[\dKk]$')
);

-- Indexes for performance
create index if not exists idx_tenants_rut on tenants(rut);
create index if not exists idx_tenants_active on tenants(is_active);

-- Trigger for updated_at
create or replace function update_updated_at_column()
returns trigger as $$
begin
  new.updated_at = now();
  return new;
end;
$$ language plpgsql;

create trigger update_tenants_updated_at
  before update on tenants
  for each row
  execute function update_updated_at_column();

-- ============================================================================
-- 2) TENANT SERVICES - Connected services per tenant
-- ============================================================================

create table if not exists tenant_services (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references tenants(id) on delete cascade,
  service_type text not null check (service_type in ('shopify', 'odoo', 'chatwoot', 'n8n')),
  status text not null default 'pending' check (status in ('pending', 'connected', 'error', 'disconnected')),
  external_id text,       -- shop_domain, odoo db, inbox_id, workflow_id
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  
  -- One service per tenant
  constraint unique_tenant_service unique (tenant_id, service_type)
);

-- Indexes
create index if not exists idx_tenant_services_tenant on tenant_services(tenant_id);
create index if not exists idx_tenant_services_type on tenant_services(service_type);
create index if not exists idx_tenant_services_status on tenant_services(status);

-- Trigger for updated_at
create trigger update_tenant_services_updated_at
  before update on tenant_services
  for each row
  execute function update_updated_at_column();

-- ============================================================================
-- 3) TENANT EVENTS - Event log for onboarding and operations
-- ============================================================================

create table if not exists tenant_events (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid references tenants(id) on delete cascade,
  event_type text not null,
  -- Event types: 
  --   'onboard_started', 'onboard_completed'
  --   'shopify_connected', 'shopify_disconnected'
  --   'odoo_connected', 'odoo_error'
  --   'chatwoot_connected', 'n8n_workflow_triggered'
  payload jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

-- Indexes
create index if not exists idx_tenant_events_tenant on tenant_events(tenant_id);
create index if not exists idx_tenant_events_type on tenant_events(event_type);
create index if not exists idx_tenant_events_created on tenant_events(created_at desc);

-- ============================================================================
-- ROW LEVEL SECURITY (RLS) - Optional, enable when ready
-- ============================================================================

-- Enable RLS
-- alter table tenants enable row level security;
-- alter table tenant_services enable row level security;
-- alter table tenant_events enable row level security;

-- Policy example: tenants can only see their own data
-- create policy "Tenants can view own data"
--   on tenants for select
--   using (rut = current_setting('app.current_tenant_rut')::text);

-- ============================================================================
-- HELPER FUNCTIONS
-- ============================================================================

-- Function to get tenant by RUT
create or replace function get_tenant_by_rut(p_rut text)
returns setof tenants as $$
begin
  return query
  select * from tenants
  where rut = p_rut;
end;
$$ language plpgsql;

-- Function to get tenant services
create or replace function get_tenant_services(p_tenant_id uuid)
returns setof tenant_services as $$
begin
  return query
  select * from tenant_services
  where tenant_id = p_tenant_id
  order by created_at;
end;
$$ language plpgsql;

-- Function to log tenant event
create or replace function log_tenant_event(
  p_tenant_id uuid,
  p_event_type text,
  p_payload jsonb default '{}'::jsonb
)
returns uuid as $$
declare
  v_event_id uuid;
begin
  insert into tenant_events (tenant_id, event_type, payload)
  values (p_tenant_id, p_event_type, p_payload)
  returning id into v_event_id;
  
  return v_event_id;
end;
$$ language plpgsql;

-- ============================================================================
-- COMMENTS
-- ============================================================================

comment on table tenants is 'Core tenant table - one row per Chilean RUT';
comment on table tenant_services is 'Connected services per tenant (Shopify, Odoo, Chatwoot, n8n)';
comment on table tenant_events is 'Event log for tenant operations and onboarding';

comment on column tenants.rut is 'Chilean RUT (format: 12345678-9)';
comment on column tenant_services.service_type is 'Type of service: shopify, odoo, chatwoot, n8n';
comment on column tenant_services.external_id is 'External identifier (shop domain, db name, inbox id, etc)';
comment on column tenant_services.metadata is 'Service-specific metadata (webhooks, modules, etc)';
