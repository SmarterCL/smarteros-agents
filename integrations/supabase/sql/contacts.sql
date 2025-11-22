-- Contacts table for unified contact form
create table if not exists public.contacts (
  id uuid primary key default gen_random_uuid(),
  created_at timestamptz default now(),
  name text not null,
  email text not null,
  message text not null,
  phone text,
  source text,
  domain text,
  status text default 'new'
);

-- Basic RLS allowing only service role. App server uses service key.
alter table public.contacts enable row level security;
drop policy if exists contacts_no_anon on public.contacts;
create policy contacts_no_anon on public.contacts for all using (false) with check (false);
