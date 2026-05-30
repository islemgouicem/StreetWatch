-- StreetWatch Phase 4: user preferences
-- Run this after phase_03_performance_indexes.sql

create table if not exists public.user_preferences (
  user_id uuid primary key references public.users(id) on delete cascade,
  incident_digest boolean not null default true,
  milestone_alerts boolean not null default true,
  product_updates boolean not null default false,
  two_factor_enabled boolean not null default false,
  biometric_lock boolean not null default false,
  location_masking boolean not null default false,
  theme text not null default 'streetwatch',
  dark_mode boolean not null default false,
  language text not null default 'en',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

drop trigger if exists trg_user_preferences_updated_at on public.user_preferences;
create trigger trg_user_preferences_updated_at
before update on public.user_preferences
for each row
execute function public.set_updated_at();

alter table if exists public.user_preferences enable row level security;

drop policy if exists user_preferences_select_self on public.user_preferences;
drop policy if exists user_preferences_insert_self on public.user_preferences;
drop policy if exists user_preferences_update_self on public.user_preferences;

create policy user_preferences_select_self
on public.user_preferences
for select
to authenticated
using (user_id = auth.uid());

create policy user_preferences_insert_self
on public.user_preferences
for insert
to authenticated
with check (user_id = auth.uid());

create policy user_preferences_update_self
on public.user_preferences
for update
to authenticated
using (user_id = auth.uid())
with check (user_id = auth.uid());
