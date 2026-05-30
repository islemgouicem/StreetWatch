-- StreetWatch Phase 7: auditable point transactions
-- Run this after phase_06_postgis_nearby_reports.sql

create table if not exists public.point_transactions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.users(id) on delete cascade,
  source_type text not null,
  source_id text,
  delta integer not null,
  reason text,
  created_at timestamptz not null default now()
);

create index if not exists idx_point_transactions_user_created_at
on public.point_transactions (user_id, created_at desc);

alter table if exists public.point_transactions enable row level security;

drop policy if exists point_transactions_select_self on public.point_transactions;
drop policy if exists point_transactions_insert_self on public.point_transactions;
drop policy if exists point_transactions_select_public on public.point_transactions;

create policy point_transactions_select_self
on public.point_transactions
for select
to authenticated
using (user_id = auth.uid());

create policy point_transactions_select_public
on public.point_transactions
for select
to authenticated
using (true);

create policy point_transactions_insert_self
on public.point_transactions
for insert
to authenticated
with check (user_id = auth.uid());
