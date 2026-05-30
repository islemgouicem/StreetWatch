-- StreetWatch Phase 1: Supabase schema (run in Supabase SQL editor)
-- Supabase is the single source of truth for schema.

create extension if not exists postgis;
create extension if not exists pgcrypto;

do $$
begin
  if not exists (select 1 from pg_type where typname = 'damage_type_enum') then
    create type damage_type_enum as enum ('pothole', 'crack', 'broken_sign', 'flooding', 'debris', 'other');
  end if;
end
$$;

do $$
begin
  if not exists (select 1 from pg_type where typname = 'severity_enum') then
    create type severity_enum as enum ('low', 'medium', 'high');
  end if;
end
$$;

do $$
begin
  if not exists (select 1 from pg_type where typname = 'report_status_enum') then
    create type report_status_enum as enum ('pending', 'verified', 'rejected', 'under_review', 'resolved');
  end if;
end
$$;

create table if not exists public.users (
  id uuid primary key,
  email text not null unique,
  username text not null unique,
  full_name text,
  avatar_url text,
  is_active boolean not null default true,
  is_admin boolean not null default false,
  points integer not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.badges (
  id uuid primary key default gen_random_uuid(),
  code text not null unique,
  name text not null,
  description text,
  points_reward integer not null default 0,
  created_at timestamptz not null default now()
);

create table if not exists public.reports (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.users(id) on delete cascade,
  image_url text not null,
  damage_type damage_type_enum not null,
  severity severity_enum not null,
  severity_confidence numeric(5,4),
  description text,
  latitude numeric(10,8) not null,
  longitude numeric(11,8) not null,
  location geography(point, 4326),
  status report_status_enum not null default 'pending',
  verification_count integer not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.user_badges (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.users(id) on delete cascade,
  badge_id uuid not null references public.badges(id) on delete cascade,
  awarded_at timestamptz not null default now(),
  unique (user_id, badge_id)
);

create table if not exists public.votes (
  id uuid primary key default gen_random_uuid(),
  report_id uuid not null references public.reports(id) on delete cascade,
  user_id uuid not null references public.users(id) on delete cascade,
  value smallint not null default 1 check (value in (-1, 1)),
  created_at timestamptz not null default now(),
  unique (report_id, user_id)
);

create or replace function public.set_updated_at()
returns trigger as $$
begin
  new.updated_at = now();
  return new;
end;
$$ language plpgsql;

create or replace function public.set_report_location()
returns trigger as $$
begin
  new.location = ST_SetSRID(ST_MakePoint(new.longitude, new.latitude), 4326)::geography;
  return new;
end;
$$ language plpgsql;

drop trigger if exists trg_users_updated_at on public.users;
create trigger trg_users_updated_at
before update on public.users
for each row
execute function public.set_updated_at();

drop trigger if exists trg_reports_updated_at on public.reports;
create trigger trg_reports_updated_at
before update on public.reports
for each row
execute function public.set_updated_at();

drop trigger if exists trg_reports_set_location on public.reports;
create trigger trg_reports_set_location
before insert or update of latitude, longitude on public.reports
for each row
execute function public.set_report_location();
