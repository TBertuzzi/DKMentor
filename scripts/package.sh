#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
VERSION="$(awk -F': ' '/^## Version:/ {print $2}' "$ROOT/DKMentor.toc")"
OUT="$ROOT/release"
STAGE="$OUT/DKMentor"
rm -rf "$OUT"
mkdir -p "$STAGE"
for f in DKMentor.toc Localization.lua Data.lua Builds.lua Guides.lua Voices.lua Core.lua CHANGELOG.md LICENSE THIRD_PARTY_NOTICES.md; do
  cp "$ROOT/$f" "$STAGE/$f"
done
(cd "$OUT" && zip -qr "DKMentor-v${VERSION}-CurseForge.zip" DKMentor)
echo "$OUT/DKMentor-v${VERSION}-CurseForge.zip"
