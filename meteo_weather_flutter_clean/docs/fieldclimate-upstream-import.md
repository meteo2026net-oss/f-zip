# Upstream FieldClimate collector import

The upstream repository is linked as a Git submodule:

- Repository: https://github.com/gfa437926-tech/metra-fieldclimate-collector
- Pinned upstream commit: `dbde3853031a9f76561a7716e755cb4f20260540`
- Local path: `integrations/metra-fieldclimate-collector`

## Why this is a submodule

The upstream repository currently has no declared open-source license file or SPDX license metadata. A Git submodule preserves the upstream repository and its authorship without copying its source files into this project as if they were relicensed. Before vendoring or modifying and redistributing those files, obtain and record the appropriate permission/license.

## Clone with the integration source

```bash
git clone --recurse-submodules https://github.com/meteo2026net-oss/f-zip.git
```

If the main repository is already cloned:

```bash
git submodule update --init --recursive
```

## Integration status

This imports the upstream source repository into the project workspace; it does not by itself make the collector operational inside the Syrian Meteorological Center app.

The upstream README states that its FieldClimate data is kept in separate `fieldclimate_*` tables and is not merged into classic METRA `stations` data. Its documented unified stations API is a contract only, not an implemented endpoint. The app integration still requires:

1. Inspecting the authoritative classic/manual station schema in the target Supabase project.
2. Verifying station identity mappings; never match only by similar station names.
3. Preserving classic, manual, and FieldClimate observations separately with source provenance.
4. Implementing and testing a secure unified read API/repository.
5. Keeping FieldClimate OAuth credentials and Supabase service-role credentials on the server only.

The submodule is pinned to a commit for reproducibility. Update it only after reviewing upstream changes and the integration tests.
