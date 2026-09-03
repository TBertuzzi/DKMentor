# DK Mentor 2.0.0 — Validation Report

Validation date: 2026-08-25
Target: World of Warcraft Retail / Interface 120100

## Static checks completed

- `texluac -p` passed for `Localization.lua`, `Data.lua`, `Builds.lua`, `Guides.lua`, `Codex.lua`, `Voices.lua`, and `Core.lua`.
- `python3 scripts/validate.py` passed for DK Mentor 2.0.0.
- `texlua tests/codex_smoke.lua` passed with all seven Codex sections and Blood/Frost/Unholy content checks.
- Static addon-method call scan found no unresolved DK Mentor method calls after removing the loadout engine.
- Static responsibility-boundary scan confirmed the active source no longer contains the retired automatic profile/spec/talent/equipment/Loot Spec/Dungeon Override engine entry points.
- Validator confirms the main UI has only Combat / DK Codex / Settings and that the optional Loadout Pilot handoff exists.
- Validator confirms schema remains 29, legacy auto-switch flags are disabled when present, and legacy mapping tables are not deleted.
- Validator retains Midnight 12.1 secret-aspect guards for Blizzard AuraContainer/AuraButton usage.
- Validator retains DK Resources, DK Arcs, Runeforge/Ghoul, interrupt alert, proc tracking, language, and HUD-layout regression guards.

## Important limitation

These are static/syntax/package checks only. The 2.0.0 branch must still be tested inside the live WoW Retail 12.1 client, especially upgrading from an existing 1.x SavedVariables file and confirming no automatic specialization/talent/gear/Loot Specialization changes occur.

See `TESTING_v2.0.0.md` before promoting this development build to a public stable release.
