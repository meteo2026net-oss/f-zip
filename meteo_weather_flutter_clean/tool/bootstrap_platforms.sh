#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

if [[ -f "$ROOT/web/index.html" ]]; then
  cp "$ROOT/web/index.html" "$TMP/index.html"
fi

flutter create \
  --platforms=android,web \
  --android-language java \
  --project-name flutter_meteo_weather \
  --org com.mcnc.weather \
  "$TMP/scaffold"

rm -rf "$ROOT/android" "$ROOT/web"
cp -R "$TMP/scaffold/android" "$ROOT/android"
cp -R "$TMP/scaffold/web" "$ROOT/web"

if [[ -f "$TMP/index.html" ]]; then
  cp "$TMP/index.html" "$ROOT/web/index.html"
fi

echo "Android and Web platform scaffolding generated."
