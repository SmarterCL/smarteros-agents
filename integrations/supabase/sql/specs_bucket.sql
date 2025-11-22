-- Create private bucket for specs-only artifacts
do $$ begin
  insert into storage.buckets (id, name, public)
  values ('specs', 'specs', false);
exception when unique_violation then
  null;
end $$;

-- RLS policies: only service role or a dedicated role can read
-- Assumes a role 'specs_reader' will be created and assumed by Edge Functions

-- Allow service_role full access
create policy if not exists specs_service_full on storage.objects
  for all using (true) with check (true);

-- Restrict read to bucket 'specs' and role 'specs_reader'
create policy if not exists specs_reader_read on storage.objects
  for select using (
    bucket_id = 'specs' and
    (auth.role() = 'service_role' or current_role = 'specs_reader')
  );

-- Optional: disallow anon/auth insert/update/delete in specs bucket
create policy if not exists specs_no_write_anon on storage.objects
  for insert to anon, authenticated using (false) with check (false);
create policy if not exists specs_no_update_anon on storage.objects
  for update to anon, authenticated using (false) with check (false);
create policy if not exists specs_no_delete_anon on storage.objects
  for delete to anon, authenticated using (false);

-- Helper view (optional) to list objects from specs bucket
create or replace view public.specs_files as
  select id, name, bucket_id, metadata, created_at, updated_at
  from storage.objects where bucket_id = 'specs';
