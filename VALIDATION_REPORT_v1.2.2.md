# Validation Report - DK Mentor 1.2.2

Date: 2026-08-25
Target: World of Warcraft Retail 12.1.0 / Interface 120100
SavedVariables schema: 29

## Completed checks

- Confirmed `DKMentor.toc` and `Data.lua` report version `1.2.2`.
- Parsed `Localization.lua`, `Data.lua`, `Builds.lua`, `Guides.lua`, `Voices.lua`, and `Core.lua` successfully with `texluac -p`.
- Ran `scripts/validate.py` successfully.
- Confirmed the schema-29 upgrade uses the already-declared `DeepCopy()` helper for Dungeon -> Mythic+ talent and equipment binding migration.
- Confirmed no runtime `CopyTableDeep()` reference remains in addon code.
- Added regression checks requiring `DeepCopy()` to be declared before `InitializeDatabase()` and used by both schema-29 mapping copies.
- Preserved 1.2.1 Dungeon/Mythic+ profiles, unified dungeon overrides, Loot Specialization, role protection, picker layering, and gear retry guards.

## Live-client limitation

Static validation cannot prove the full WoW login/upgrade path. Install 1.2.2 over the existing schema-28 SavedVariables and verify `/reload` completes without the 1.2.1 `InitializeDatabase` error before publishing.
