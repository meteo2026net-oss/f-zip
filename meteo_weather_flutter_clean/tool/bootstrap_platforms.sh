#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

if [[ -f "$ROOT/web/index.html" ]]; then
  cp "$ROOT/web/index.html" "$TMP/index.html"
fi
if [[ -f "$ROOT/web/manifest.json" ]]; then
  cp "$ROOT/web/manifest.json" "$TMP/manifest.json"
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

# Release builds merge src/main only; INTERNET must be declared there.
MAIN_MANIFEST="$ROOT/android/app/src/main/AndroidManifest.xml"
if ! grep -q 'android.permission.INTERNET' "$MAIN_MANIFEST"; then
  sed -i '2i\    <uses-permission android:name="android.permission.INTERNET"/>' "$MAIN_MANIFEST"
fi

if [[ -f "$TMP/index.html" ]]; then
  cp "$TMP/index.html" "$ROOT/web/index.html"
fi
if [[ -f "$TMP/manifest.json" ]]; then
  cp "$TMP/manifest.json" "$ROOT/web/manifest.json"
fi

echo "Android and Web platform scaffolding generated."
