-- StreetWatch Phase 2: RLS and Storage Policies
-- Run this in Supabase SQL Editor.

-- 1) Enable RLS
alter table if exists public.users enable row level security;
alter table if exists public.reports enable row level security;
alter table if exists public.badges enable row level security;
alter table if exists public.user_badges enable row level security;
alter table if exists public.votes enable row level security;

-- 2) Drop existing policies if re-running
drop policy if exists users_select_self on public.users;
drop policy if exists users_update_self on public.users;
drop policy if exists users_select_public_profile on public.users;

drop policy if exists reports_select_public on public.reports;
drop policy if exists reports_select_own on public.reports;
drop policy if exists reports_insert_own on public.reports;
drop policy if exists reports_update_own_pending on public.reports;
drop policy if exists reports_delete_own_pending on public.reports;

drop policy if exists badges_select_all on public.badges;

drop policy if exists user_badges_select_self on public.user_badges;
drop policy if exists user_badges_select_public_by_user on public.user_badges;

drop policy if exists votes_select_public on public.votes;
drop policy if exists votes_insert_own on public.votes;
drop policy if exists votes_update_own on public.votes;
drop policy if exists votes_delete_own on public.votes;

-- 3) users policies
create policy users_select_self
on public.users
for select
to authenticated
using (id = auth.uid());

create policy users_update_self
on public.users
for update
to authenticated
using (id = auth.uid())
with check (id = auth.uid());

create policy users_select_public_profile
on public.users
for select
to authenticated
using (true);

-- 4) reports policies
create policy reports_select_public
on public.reports
for select
to authenticated
using (status in ('verified', 'rejected'));

create policy reports_select_own
on public.reports
for select
to authenticated
using (user_id = auth.uid());

create policy reports_insert_own
on public.reports
for insert
to authenticated
with check (user_id = auth.uid());

create policy reports_update_own_pending
on public.reports
for update
to authenticated
using (user_id = auth.uid() and status = 'pending')
with check (user_id = auth.uid());

create policy reports_delete_own_pending
on public.reports
for delete
to authenticated
using (user_id = auth.uid() and status = 'pending');

-- 5) badges policies
create policy badges_select_all
on public.badges
for select
to authenticated
using (true);

-- 6) user_badges policies
create policy user_badges_select_self
on public.user_badges
for select
to authenticated
using (user_id = auth.uid());

create policy user_badges_select_public_by_user
on public.user_badges
for select
to authenticated
using (true);

-- 7) votes policies
create policy votes_select_public
on public.votes
for select
to authenticated
using (true);

create policy votes_insert_own
on public.votes
for insert
to authenticated
with check (user_id = auth.uid());

create policy votes_update_own
on public.votes
for update
to authenticated
using (user_id = auth.uid())
with check (user_id = auth.uid());

create policy votes_delete_own
on public.votes
for delete
to authenticated
using (user_id = auth.uid());

-- 8) Storage bucket and policies
insert into storage.buckets (id, name, public)
values ('reports-images', 'reports-images', false)
on conflict (id) do nothing;

insert into storage.buckets (id, name, public)
values ('avatars', 'avatars', true)
on conflict (id) do nothing;

drop policy if exists reports_images_read on storage.objects;
drop policy if exists reports_images_insert on storage.objects;
drop policy if exists reports_images_update on storage.objects;
drop policy if exists reports_images_delete on storage.objects;
drop policy if exists avatars_read_public on storage.objects;
drop policy if exists avatars_insert_own on storage.objects;
drop policy if exists avatars_update_own on storage.objects;
drop policy if exists avatars_delete_own on storage.objects;

create policy reports_images_read
on storage.objects
for select
to authenticated
using (bucket_id = 'reports-images');

create policy reports_images_insert
on storage.objects
for insert
to authenticated
with check (
  bucket_id = 'reports-images'
  and auth.uid()::text = (storage.foldername(name))[1]
);

create policy reports_images_update
on storage.objects
for update
to authenticated
using (
  bucket_id = 'reports-images'
  and auth.uid()::text = (storage.foldername(name))[1]
)
with check (
  bucket_id = 'reports-images'
  and auth.uid()::text = (storage.foldername(name))[1]
);

create policy reports_images_delete
on storage.objects
for delete
to authenticated
using (
  bucket_id = 'reports-images'
  and auth.uid()::text = (storage.foldername(name))[1]
);

create policy avatars_read_public
on storage.objects
for select
to public
using (bucket_id = 'avatars');

create policy avatars_insert_own
on storage.objects
for insert
to authenticated
with check (
  bucket_id = 'avatars'
  and auth.uid()::text = (storage.foldername(name))[1]
);

create policy avatars_update_own
on storage.objects
for update
to authenticated
using (
  bucket_id = 'avatars'
  and auth.uid()::text = (storage.foldername(name))[1]
)
with check (
  bucket_id = 'avatars'
  and auth.uid()::text = (storage.foldername(name))[1]
);

create policy avatars_delete_own
on storage.objects
for delete
to authenticated
using (
  bucket_id = 'avatars'
  and auth.uid()::text = (storage.foldername(name))[1]
);