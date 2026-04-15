-- StreetWatch Phase 10: make report images publicly readable for the web map
-- Run this after phase_09_enum_backfill.sql

update storage.buckets
set public = true
where id = 'reports-images';

drop policy if exists reports_images_read on storage.objects;

create policy reports_images_read
on storage.objects
for select
to public
using (bucket_id = 'reports-images');
