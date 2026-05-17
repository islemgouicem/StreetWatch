alter table if exists public.users
add column if not exists bio text;
