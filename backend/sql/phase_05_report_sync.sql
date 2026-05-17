-- StreetWatch Phase 5: offline-safe report sync
-- Run this after phase_04_user_preferences.sql

alter table if exists public.reports
add column if not exists client_report_id text;

create unique index if not exists idx_reports_user_client_report_id
on public.reports (user_id, client_report_id)
where client_report_id is not null;
