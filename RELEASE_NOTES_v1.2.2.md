# DK Mentor 1.2.2

Version 1.2.2 is a focused hotfix for the 1.2.1 Loadouts 2.0 database migration.

## Fixed

- Fixed a Lua error during login or `/reload` when upgrading a schema-28 database to schema 29.
- The 1.2.1 migration referenced `CopyTableDeep()`, but DK Mentor already provides the helper as `DeepCopy()`.
- Existing Dungeon talent-loadout and equipment bindings now copy safely into the new Mythic+ defaults during the one-time upgrade.

## Preserved

- Separate Dungeon and Mythic+ default profiles.
- One dungeon override shared across Normal, Heroic, Mythic 0, and Mythic+.
- Per-dungeon Loot Specialization overrides and restoration.
- Role-safe automatic playing-spec switching.
- Dungeon Override pickers rendering above the editor.
- Compact one-line Build HUD and manual Blood/Frost/Unholy switching from the specialization icon.

## Compatibility

- Retail interface: 12.1.0 / 120100.
- SavedVariables schema remains 29.
- Do not delete `DKMentorDB`; this hotfix is specifically designed to migrate the existing schema-28 data safely.
