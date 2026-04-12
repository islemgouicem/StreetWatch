-- StreetWatch Phase 3: Performance indexes (run in Supabase SQL editor)

create index if not exists idx_reports_location_gist
on public.reports
using gist (location)
where location is not null;

create index if not exists idx_reports_status_created_at
on public.reports (status, created_at desc);

create unique index if not exists idx_votes_report_user
on public.votes (report_id, user_id);

create index if not exists idx_reports_user_id
on public.reports (user_id);

create index if not exists idx_reports_created_at
on public.reports (created_at desc);
