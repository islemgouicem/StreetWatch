-- StreetWatch Phase 9: backfill missing enum values on existing Supabase projects
-- Run this if enums were created before the latest schema version.

alter type damage_type_enum add value if not exists 'pothole';
alter type damage_type_enum add value if not exists 'crack';
alter type damage_type_enum add value if not exists 'broken_sign';
alter type damage_type_enum add value if not exists 'flooding';
alter type damage_type_enum add value if not exists 'debris';
alter type damage_type_enum add value if not exists 'other';

alter type severity_enum add value if not exists 'low';
alter type severity_enum add value if not exists 'medium';
alter type severity_enum add value if not exists 'high';

alter type report_status_enum add value if not exists 'pending';
alter type report_status_enum add value if not exists 'verified';
alter type report_status_enum add value if not exists 'rejected';
alter type report_status_enum add value if not exists 'under_review';
alter type report_status_enum add value if not exists 'resolved';
