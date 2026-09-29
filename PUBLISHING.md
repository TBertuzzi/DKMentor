# Publishing DK Mentor 3.3.3

DK Mentor 3.3.3 is a focused Unholy PvE meta consolidation after the September 22 tuning and September 23 Blightfall hotfix. It preserves the tested 3.3.2 feature/runtime boundary and changes only source-backed guidance, localization, freshness metadata, and validation coverage.

## Before publishing

1. Run `python3 scripts/validate.py`.
2. Run all Lua smoke tests in `tests/`.
3. Complete `TESTING_v3.3.3.md` in the live Retail client.
4. Verify Unholy Raid, Mythic+, Dungeon, and Delve show San'layn/Blightfall first as Recommended, with Rider as Alternative.
5. Verify Open World still shows Rider as Recommended.
6. Verify PvP still shows Pet/Rider as provisional Recommended and Disease/San'layn as Alternative with REVIEW PENDING.
7. Verify Blood/Frost REVIEW PENDING states remain readable.
8. Confirm the final CurseForge ZIP contains one top-level `DKMentor/` directory.
9. Confirm the source archive excludes generated `release/` staging content.

## CurseForge

Upload `DKMentor-v3.3.3-CurseForge.zip` only after live validation.

Suggested display name: `DK Mentor 3.3.3 - Unholy San'layn / Blightfall Refresh`

Use `CURSEFORGE_CHANGELOG_v3.3.3.md` as the file changelog.

## GitHub

Tag: `v3.3.3`

Suggested release title: `DK Mentor 3.3.3 - Unholy San'layn / Blightfall Refresh`

Use `RELEASE_NOTES_v3.3.3.md` as the GitHub release body.
