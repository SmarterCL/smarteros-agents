-- ============================================================================
-- SUPABASE SCHEMA - ACCOUNTING & DTE ENGINE
-- ============================================================================
-- Version: 1.0.0
-- Description: Motor de contabilidad y cola DTE para SmarterOS
-- Author: SmarterOS Team
-- Date: 2025-11-23
-- ============================================================================

-- ============================================================================
-- 1) SALES EVENTS - Ventas normalizadas (agnóstico de origen)
-- ============================================================================

create table if not exists sales_events (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references tenants(id) on delete cascade,
  
  -- Origen de la venta
  source text not null check (source in ('shopify', 'odoo', 'manual', 'api')),
  external_id text not null, -- ej: shopify order id
  
  -- Cliente
  rut_cliente text,
  nombre_cliente text,
  email_cliente text,
  
  -- Montos
  total_neto numeric(18,2) not null,
  total_iva numeric(18,2) not null,
  total_bruto numeric(18,2) not null,
  currency text not null default 'CLP',
  
  -- Estado del procesamiento
  status text not null default 'ingested' check (status in (
    'ingested',      -- Recién ingresada
    'accounted',     -- Contabilizada en Odoo
    'dte_queued',    -- En cola para DTE
    'dte_sent',      -- DTE enviado a SII
    'error'          -- Error en procesamiento
  )),
  
  -- Metadata
  raw_payload jsonb not null default '{}'::jsonb,
  error_message text,
  
  -- Timestamps
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  processed_at timestamptz,
  
  -- Constraints
  unique(tenant_id, source, external_id)
);

-- Indexes
create index if not exists idx_sales_events_tenant on sales_events(tenant_id);
create index if not exists idx_sales_events_status on sales_events(status);
create index if not exists idx_sales_events_source on sales_events(source);
create index if not exists idx_sales_events_created on sales_events(created_at desc);

-- Trigger for updated_at
create trigger update_sales_events_updated_at
  before update on sales_events
  for each row
  execute function update_updated_at_column();

-- ============================================================================
-- 2) ACCOUNTING EVENTS - Registro de acciones contables
-- ============================================================================

create table if not exists accounting_events (
  id uuid primary key default gen_random_uuid(),
  sales_event_id uuid not null references sales_events(id) on delete cascade,
  
  -- Tipo de evento contable
  event_type text not null,
  -- Tipos:
  --   'odoo_partner_created', 'odoo_partner_updated'
  --   'odoo_sale_order_created', 'odoo_sale_order_confirmed'
  --   'odoo_invoice_created', 'odoo_invoice_validated'
  --   'dte_generated', 'dte_sent', 'dte_accepted', 'dte_rejected'
  
  -- Datos del evento
  payload jsonb not null default '{}'::jsonb,
  
  -- Timestamp
  created_at timestamptz not null default now()
);

-- Indexes
create index if not exists idx_accounting_events_sales on accounting_events(sales_event_id);
create index if not exists idx_accounting_events_type on accounting_events(event_type);
create index if not exists idx_accounting_events_created on accounting_events(created_at desc);

-- ============================================================================
-- 3) DTE QUEUE - Cola de DTEs para envío al SII
-- ============================================================================

create table if not exists dte_queue (
  id uuid primary key default gen_random_uuid(),
  sales_event_id uuid not null references sales_events(id) on delete cascade,
  tenant_id uuid not null references tenants(id) on delete cascade,
  
  -- Emisor
  rut_emisor text not null,
  razon_social_emisor text,
  
  -- Tipo de DTE
  tipo_dte text not null check (tipo_dte in (
    '33',  -- Factura Electrónica
    '34',  -- Factura Exenta
    '39',  -- Boleta Electrónica
    '41',  -- Boleta Exenta
    '56',  -- Nota de Débito
    '61'   -- Nota de Crédito
  )),
  folio integer,
  
  -- Estado
  status text not null default 'pending' check (status in (
    'pending',       -- En cola, no enviado
    'generating',    -- Generando XML
    'ready',         -- XML listo, esperando envío
    'sent',          -- Enviado a SII
    'accepted',      -- Aceptado por SII
    'rejected',      -- Rechazado por SII
    'error'          -- Error en proceso
  )),
  
  -- SII
  sii_track_id text,
  sii_response jsonb,
  sii_error_code text,
  sii_error_message text,
  
  -- XML DTE
  dte_xml text,
  dte_signature text,
  
  -- Timestamps
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  sent_at timestamptz,
  accepted_at timestamptz,
  
  -- Retry logic
  retry_count integer not null default 0,
  max_retries integer not null default 3,
  next_retry_at timestamptz
);

-- Indexes
create index if not exists idx_dte_queue_tenant on dte_queue(tenant_id);
create index if not exists idx_dte_queue_sales_event on dte_queue(sales_event_id);
create index if not exists idx_dte_queue_status on dte_queue(status);
create index if not exists idx_dte_queue_tipo on dte_queue(tipo_dte);
create index if not exists idx_dte_queue_next_retry on dte_queue(next_retry_at) 
  where status = 'error' and retry_count < max_retries;

-- Trigger for updated_at
create trigger update_dte_queue_updated_at
  before update on dte_queue
  for each row
  execute function update_updated_at_column();

-- ============================================================================
-- 4) DTE LOG - Historial completo de DTEs
-- ============================================================================

create table if not exists dte_log (
  id uuid primary key default gen_random_uuid(),
  dte_queue_id uuid references dte_queue(id) on delete set null,
  tenant_id uuid not null references tenants(id) on delete cascade,
  
  tipo_dte text not null,
  folio integer,
  rut_emisor text not null,
  rut_receptor text,
  
  monto_total numeric(18,2),
  fecha_emision date not null,
  
  status text not null,
  sii_track_id text,
  
  created_at timestamptz not null default now()
);

-- Indexes
create index if not exists idx_dte_log_tenant on dte_log(tenant_id);
create index if not exists idx_dte_log_fecha on dte_log(fecha_emision desc);
create index if not exists idx_dte_log_tipo on dte_log(tipo_dte);

-- ============================================================================
-- HELPER FUNCTIONS
-- ============================================================================

-- Function to log accounting event
create or replace function log_accounting_event(
  p_sales_event_id uuid,
  p_event_type text,
  p_payload jsonb default '{}'::jsonb
)
returns uuid as $$
declare
  v_event_id uuid;
begin
  insert into accounting_events (sales_event_id, event_type, payload)
  values (p_sales_event_id, p_event_type, p_payload)
  returning id into v_event_id;
  
  return v_event_id;
end;
$$ language plpgsql;

-- Function to update sales_event status
create or replace function update_sales_event_status(
  p_sales_event_id uuid,
  p_new_status text
)
returns void as $$
begin
  update sales_events
  set 
    status = p_new_status,
    processed_at = case when p_new_status in ('accounted', 'dte_sent') 
                        then now() else processed_at end
  where id = p_sales_event_id;
end;
$$ language plpgsql;

-- Function to get pending DTEs
create or replace function get_pending_dtes(p_limit integer default 10)
returns setof dte_queue as $$
begin
  return query
  select * from dte_queue
  where status = 'pending'
  order by created_at
  limit p_limit;
end;
$$ language plpgsql;

-- Function to get DTEs for retry
create or replace function get_dtes_for_retry()
returns setof dte_queue as $$
begin
  return query
  select * from dte_queue
  where status = 'error'
    and retry_count < max_retries
    and (next_retry_at is null or next_retry_at <= now())
  order by next_retry_at nulls first
  limit 50;
end;
$$ language plpgsql;

-- ============================================================================
-- VIEWS
-- ============================================================================

-- View: Sales with DTE status
create or replace view sales_with_dte as
select 
  se.*,
  dq.id as dte_id,
  dq.tipo_dte,
  dq.folio,
  dq.status as dte_status,
  dq.sii_track_id
from sales_events se
left join dte_queue dq on dq.sales_event_id = se.id;

-- View: DTE statistics per tenant
create or replace view dte_stats_by_tenant as
select 
  tenant_id,
  count(*) as total_dtes,
  count(*) filter (where status = 'accepted') as accepted,
  count(*) filter (where status = 'rejected') as rejected,
  count(*) filter (where status = 'pending') as pending,
  count(*) filter (where status = 'error') as errors
from dte_queue
group by tenant_id;

-- ============================================================================
-- COMMENTS
-- ============================================================================

comment on table sales_events is 'Ventas normalizadas independientes del origen';
comment on table accounting_events is 'Log de acciones contables ejecutadas';
comment on table dte_queue is 'Cola de DTEs para envío al SII Chile';
comment on table dte_log is 'Historial completo de DTEs emitidos';

comment on column sales_events.source is 'Origen: shopify, odoo, manual, api';
comment on column sales_events.status is 'Estado: ingested → accounted → dte_queued → dte_sent';
comment on column dte_queue.tipo_dte is 'Tipo DTE: 33=Factura, 39=Boleta, 61=NC';
comment on column dte_queue.status is 'Estado: pending → generating → ready → sent → accepted/rejected';
