# DK Mentor 1.2.0 - Validation report

Validation date: 2026-08-24

## Static validation

- `texluac -p` passed for `Localization.lua`, `Data.lua`, `Builds.lua`, `Guides.lua`, `Voices.lua`, and `Core.lua`.
- `python3 scripts/validate.py` passed for version `1.2.0` / Retail interface `120100`.
- No duplicate `addon:` method definitions were detected in `Core.lua`.
- No duplicate top-level `local function` definitions were detected in `Core.lua`.
- Localization printf placeholder parity check passed for all directly paired `P("English", "Portuguese")` entries.
- The previous text claiming specializations are never changed automatically is no longer present in `Core.lua`.
- `Core.lua` remains below Lua's top-level local-variable limit; `texluac` compilation is the authoritative guard.

## Loadouts 2.0 regression checks

- Content-level specialization mappings are persisted separately from talent and equipment mappings.
- `Spec AUTO`, `Talents AUTO`, and `Gear AUTO` remain independent switches.
- Manual Blood/Frost/Unholy switching from the compact Build HUD icon remains wired.
- Automatic specialization changes are skipped during combat.
- Dungeon/Raid automatic specialization changes include group-role protection.
- Specialization-change failures clear pending state instead of leaving the profile stuck.
- Dungeon overrides are discovered from current WoW dungeon APIs and visited instances rather than a hardcoded seasonal list.
- Equivalent Challenge Mode / instance / UI-map identities reuse existing dungeon overrides.
- Editing the override for the current dungeon re-evaluates the automatic profile immediately.
- Dungeon override components support inheritance, keep-current, and explicit values.
- Existing pre-1.2.0 SavedVariables mappings are preserved by the schema 28 migration.

## Packaging checks to perform after ZIP generation

- CurseForge package has exactly one top-level `DKMentor/` folder.
- CurseForge package contains runtime files, license/notices, and all six DK Arc textures only.
- Test package additionally contains `CHANGELOG.md`.
- GitHub package contains the full source tree and release/testing documentation.
- `zipfile.testzip()` reports no corrupt entries for all generated ZIPs.

Live WoW client testing is still required before publishing the release.
