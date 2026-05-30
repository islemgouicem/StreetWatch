-- StreetWatch Phase 6: PostGIS nearby reports RPC
-- Run this after phase_05_report_sync.sql

create or replace function public.nearby_public_reports(
  input_latitude double precision,
  input_longitude double precision,
  input_radius_km double precision default 5.0,
  input_limit integer default 50
)
returns table (
  id uuid,
  user_id uuid,
  client_report_id text,
  image_url text,
  damage_type damage_type_enum,
  severity severity_enum,
  severity_confidence numeric,
  description text,
  latitude numeric,
  longitude numeric,
  location geography,
  status report_status_enum,
  verification_count integer,
  created_at timestamptz,
  updated_at timestamptz,
  distance_meters double precision
)
language sql
stable
as $$
  select
    r.id,
    r.user_id,
    r.client_report_id,
    r.image_url,
    r.damage_type,
    r.severity,
    r.severity_confidence,
    r.description,
    r.latitude,
    r.longitude,
    r.location,
    r.status,
    r.verification_count,
    r.created_at,
    r.updated_at,
    ST_Distance(
      r.location,
      ST_SetSRID(ST_MakePoint(input_longitude, input_latitude), 4326)::geography
    ) as distance_meters
  from public.reports r
  where r.status in ('verified', 'rejected')
    and r.location is not null
    and ST_DWithin(
      r.location,
      ST_SetSRID(ST_MakePoint(input_longitude, input_latitude), 4326)::geography,
      input_radius_km * 1000.0
    )
  order by distance_meters asc, r.created_at desc
  limit greatest(1, least(input_limit, 200));
$$;
