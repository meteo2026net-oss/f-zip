# FieldClimate + MCNC unified station integration

## Goal

FieldClimate is an additional observation source inside the MCNC station experience. It must not remain a disconnected station browser, and it must not overwrite classic or manually entered observations.

## Verified repository state (2026-11-08)

- `lib/screens/fieldclimate_screen.dart` is a separate, read-only screen. It queries `fieldclimate_public_stations` and `fieldclimate_public_readings`.
- `home_weather_screen.dart` exposes that screen through a separate sensor icon.
- `lib/widgets/syrian_stations_section.dart` currently renders placeholder station cards. Its heading explicitly calls the locations illustrative, and the cards show no live measurements.
- `WeatherRepository.getSyrianWeatherStations()` returns hard-coded illustrative station values; it is not a classic/manual station feed.
- The repository currently contains one FieldClimate migration, but no authoritative classic-station or manual-observation schema, no canonical station registry, and no FieldClimate collector service/API implementation in the Flutter repository.
- The FieldClimate readings view is configured with `security_invoker = true`, while its underlying table has RLS enabled, no SELECT policy, and no SELECT grant for client roles. The current Flutter screen also sends the anon key as its bearer token. Therefore the current client read path is not a verified working authenticated data path.
- CI run 84 for commit `9edcebd1b88b8c16f2b7ff0ec177168969dd263f` was cancelled; it is not a passing build and produced no verified artifact.

## Required target architecture

1. **Canonical station identity**: each real MCNC station has one stable MCNC station code/ID, official Arabic name, governorate, coordinates, station class, and lifecycle status.
2. **Explicit source mapping**: map a FieldClimate station ID to a canonical MCNC station only after a human verifies the physical station identity. Never auto-merge solely by similar names or nearby coordinates.
3. **Separate source records**: preserve original FieldClimate payloads and classic/manual source records. Every normalized observation carries source, source record ID, observed timestamp, ingestion timestamp, unit, and quality/validation status.
4. **One station detail experience**: the existing station detail page reads observations through a unified repository and offers source filters (all / classic / manual / FieldClimate). Every displayed value shows its source and observation time.
5. **Conflict policy**: do not overwrite one source with another. If two sources report the same parameter and time, retain both records and show provenance; any preferred display value must follow an explicit, configurable quality policy.
6. **Secure ingestion**: FieldClimate OAuth client ID/secret and Supabase service-role key remain server-side. The Flutter app must never contain either secret. The app must use a properly authenticated, least-privilege read API; an anon key alone is not user authentication.
7. **Operational status**: show last successful sync, per-station freshness, sync errors, and stale-data warnings. A missing reading must remain missing, not be replaced with a forecast or synthetic value.

## Safe implementation order

- Inventory and document the real classic station and manual-entry schemas and their source identifiers.
- Create the canonical station registry and verified source-link table from the authoritative MCNC station inventory.
- Add an ingestion adapter that writes FieldClimate observations without changing classic/manual records.
- Add a unified read view/API with row-level authorization and tests for anonymous, authenticated, and unauthorized access.
- Replace the placeholder station cards with live station summaries and source badges; open the same station detail page for every source.
- Add tests for duplicate ingestion, station mapping, timestamp/time-zone handling, unit conversion, conflicting measurements, stale readings, and access control.
- Run Flutter analysis/tests/build and backend/database tests before merging.

## Merge gate

Do not merge this integration to `main` or label it operational until the actual classic/manual schemas have been inspected, source mappings are verified, the collector is deployed with server-side secrets, the client read API passes authorization tests, and CI is green. The current FieldClimate screen and migration are an initial UI/database scaffold only.
