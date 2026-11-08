-- Canonical station identity and source-preserving observations.
-- No classic/manual schema is assumed or imported by this migration.
create table if not exists public.mcnc_stations (
  id uuid primary key default gen_random_uuid(),
  code text not null unique,
  name_ar text not null,
  governorate text not null default '',
  latitude double precision not null check (latitude between -90 and 90),
  longitude double precision not null check (longitude between -180 and 180),
  station_class text,
  lifecycle_status text not null default 'active'
    check (lifecycle_status in ('active', 'inactive', 'retired')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create table if not exists public.mcnc_station_source_links (
  id uuid primary key default gen_random_uuid(),
  station_id uuid not null references public.mcnc_stations(id) on delete restrict,
  source text not null check (source in ('classic', 'manual', 'fieldclimate')),
  external_station_id text not null,
  verification_status text not null default 'pending'
    check (verification_status in ('pending', 'verified', 'rejected')),
  verified_by text,
  verified_at timestamptz,
  notes text,
  created_at timestamptz not null default now(),
  unique (source, external_station_id),
  check ((verification_status = 'verified' and verified_at is not null and verified_by is not null)
      or verification_status <> 'verified')
);
create index if not exists mcnc_station_source_links_station_idx
  on public.mcnc_station_source_links(station_id, source);
create table if not exists public.mcnc_station_observations (
  id uuid primary key default gen_random_uuid(),
  station_id uuid not null references public.mcnc_stations(id) on delete restrict,
  source text not null check (source in ('classic', 'manual', 'fieldclimate')),
  source_record_id text not null,
  parameter text not null,
  numeric_value double precision not null,
  unit text not null,
  observed_at timestamptz not null,
  ingested_at timestamptz not null default now(),
  quality text not null default 'unverified',
  raw_payload jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  unique (source, source_record_id, parameter)
);
create index if not exists mcnc_station_observations_station_time_idx
  on public.mcnc_station_observations(station_id, observed_at desc);
create index if not exists mcnc_station_observations_source_time_idx
  on public.mcnc_station_observations(source, observed_at desc);
alter table public.mcnc_stations enable row level security;
alter table public.mcnc_station_source_links enable row level security;
alter table public.mcnc_station_observations enable row level security;
revoke all on public.mcnc_stations from public, anon, authenticated;
revoke all on public.mcnc_station_source_links from public, anon, authenticated;
revoke all on public.mcnc_station_observations from public, anon, authenticated;
grant select, insert, update on public.mcnc_stations to service_role;
grant select, insert, update on public.mcnc_station_source_links to service_role;
grant select, insert, update on public.mcnc_station_observations to service_role;
create or replace view public.mcnc_verified_station_observations
with (security_invoker = true) as
select o.id, o.station_id, o.source, o.source_record_id, o.parameter,
       o.numeric_value as value, o.unit, o.observed_at, o.ingested_at, o.quality
from public.mcnc_station_observations o
join public.mcnc_station_source_links l
  on l.station_id = o.station_id
 and l.source = o.source
 and l.verification_status = 'verified';
revoke all on public.mcnc_verified_station_observations from public, anon, authenticated;
grant select on public.mcnc_verified_station_observations to service_role;
