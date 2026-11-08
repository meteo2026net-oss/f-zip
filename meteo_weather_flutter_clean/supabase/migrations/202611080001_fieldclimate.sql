-- FieldClimate collector integration.
-- Keep METRA and FieldClimate records in separate tables.
create table if not exists public.fieldclimate_stations (
  station_id text primary key,
  station_name text,
  latitude double precision,
  longitude double precision,
  altitude_m double precision,
  metadata jsonb not null default '{}'::jsonb,
  first_seen_at timestamptz not null default now(),
  last_synced_at timestamptz not null default now()
);

create table if not exists public.fieldclimate (
  id uuid primary key default gen_random_uuid(),
  station_id text not null references public.fieldclimate_stations(station_id) on delete cascade,
  station_name text,
  recorded_at timestamptz not null,
  group_name text not null check (group_name in ('hourly','daily')),
  latitude double precision,
  longitude double precision,
  altitude_m double precision,
  measurements jsonb not null default '{}'::jsonb,
  raw_data jsonb not null default '{}'::jsonb,
  fetched_at timestamptz not null default now(),
  created_at timestamptz not null default now(),
  constraint fieldclimate_station_time_group_unique unique (station_id, recorded_at, group_name)
);
create index if not exists fieldclimate_station_time_idx
  on public.fieldclimate(station_id, group_name, recorded_at desc);

alter table public.fieldclimate enable row level security;
alter table public.fieldclimate_stations enable row level security;
revoke all on public.fieldclimate from public, anon, authenticated;
revoke all on public.fieldclimate_stations from public, anon, authenticated;

create or replace view public.fieldclimate_public_stations
as
select station_id, station_name, latitude, longitude, altitude_m, last_synced_at
from public.fieldclimate_stations;

create or replace view public.fieldclimate_public_readings
with (security_invoker = true) as
select station_id, station_name, recorded_at, group_name, measurements, latitude, longitude
from public.fieldclimate;

grant select on public.fieldclimate_public_stations to anon, authenticated;
grant select on public.fieldclimate_public_readings to anon, authenticated;
