# Unified MCNC stations integration contract

## Status

This is the typed Flutter client contract and database foundation, not a claim that a production API is deployed. This repository currently has no authoritative classic/manual station schema and no implemented `/api/v1/stations` backend. The opt-in black-box tests are prepared, but cannot pass against a live service until the backend and an isolated two-organization test environment exist.

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

## Integration test suite

File: `test/integration/unified_station_api_integration_test.dart`.

This is a real HTTP black-box test suite; it does not mock the API. It is intentionally skipped unless all of these environment variables are supplied:

- `MCNC_API_BASE_URL`: deployed test API base URL.
- `MCNC_TENANT_A_JWT`: short-lived test JWT for organization A.
- `MCNC_TENANT_B_JWT`: short-lived test JWT for organization B.
- `MCNC_TENANT_A_STATION_ID`: seeded station owned by organization A.

When configured, the suite verifies:
1. Anonymous requests are rejected (401/403).
2. Organization A can read its own station.
3. Organization B cannot read organization A's station (403/404; IDOR denial).
4. Source filters return only classic observations.
5. Source filters return only manual observations.
6. Source filters return only FieldClimate observations.

Run locally from `meteo_weather_flutter_clean` after exporting the variables above:

```bash
flutter test test/integration/unified_station_api_integration_test.dart
```

Use a dedicated test deployment and test-only accounts. Do not put production JWTs, service-role keys, or FieldClimate OAuth credentials in repository files or CI logs. Add the four values as protected GitHub Actions secrets/environment variables only after the API exists and the test identities are seeded. Without those values, the integration group is skipped; a green Flutter unit-test run must not be described as a successful live authorization test.

## Remaining backend work before production

1. Inspect actual classic/manual tables, primary keys, station identifiers, units, timestamps, and organization ownership in the correct production schema.
2. Implement one adapter per source without modifying source tables.
3. Resolve the upstream FieldClimate upsert key mismatch: collector upsert uses station_id + recorded_at + group_name, while the earlier table constraint used station_id + recorded_at.
4. Implement authenticated routes and enforce organization/role authorization server-side before any query result is returned.
5. Populate the canonical station inventory and manually verify every external station mapping.
6. Seed two isolated organizations and test accounts, then execute the HTTP suite above.
7. Add database integration tests for duplicate ingestion, source conflicts, verified links, and tenant scoping once the real ownership/membership schema is known.
8. Add station-detail UI after the API and login token provider are wired.

## Current limitations

The existing home screen's 13 sample station cards and getSyrianWeatherStations() values are illustrative placeholders. They are not classic/manual observations and must not be displayed as live national station readings. The existing FieldClimate screen is also a separate legacy browser, not the unified station detail experience.
