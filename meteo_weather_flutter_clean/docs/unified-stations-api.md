# Unified MCNC stations integration contract

## Status

This is the typed Flutter client contract and database foundation, not a claim that a production API is deployed. The target repository has no authoritative classic/manual station schema and no implemented `/api/v1/stations` endpoint at this revision. Do not enable a client call until a trusted backend implements this contract and the real schemas are inspected.

## Identity and source policy

- `mcnc_stations.id` and `code` are the canonical MCNC station identity.
- `mcnc_station_source_links` maps one external station ID to one canonical station and one source (`classic`, `manual`, `fieldclimate`).
- A link is usable only after explicit verification (`verification_status=verified`, `verified_by`, `verified_at`). Names and coordinates are review aids, never an automatic merge rule.
- `mcnc_station_observations` preserves source, source record ID, parameter, numeric value, unit, observation time, ingestion time, quality, and raw payload.
- The unique key is source + source record ID + parameter. Same-time observations from different sources remain separate. No source overwrites another.
- No missing reading may be replaced by zero, a forecast, or a synthetic value.

## HTTP API

All routes require a valid authenticated user JWT in `Authorization: Bearer <access-token>`. The public Supabase anon key is not an access token. The API must enforce the user's organization/role scope and must never expose service-role or FieldClimate OAuth credentials.

### GET /api/v1/stations

Returns a JSON array with `id`, `code`, `name_ar`, `governorate`, `latitude`, and `longitude`.

### GET /api/v1/stations/{stationId}/observations

Query parameters: `source=all|classic|manual|fieldclimate` and `limit=500`.

Returns a JSON array with `id`, `station_id`, `source`, `source_record_id`, `parameter`, numeric `value`, `unit`, `observed_at`, `ingested_at`, and `quality`.

The server must validate source filters, clamp limits, return only verified station links, preserve conflicting source rows, and apply row-level authorization before returning records.

## Remaining backend work before production

1. Inspect actual classic/manual tables, primary keys, station identifiers, units, and timestamps in the production schema.
2. Implement one adapter per source without modifying source tables.
3. Resolve the upstream FieldClimate upsert key mismatch: collector upsert uses station_id + recorded_at + group_name, while the earlier table constraint used station_id + recorded_at.
4. Implement authenticated routes and test anonymous denial, cross-user/organization denial, and source filtering.
5. Populate the canonical station inventory and manually verify every external station mapping.
6. Add station-detail UI after the API and login token provider are wired.

## Current limitations

The existing home screen's 13 sample station cards and getSyrianWeatherStations() values are illustrative placeholders. They are not classic/manual observations and must not be displayed as live national station readings.
