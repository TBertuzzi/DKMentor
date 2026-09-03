# Validation Report - DK Mentor 1.3.0

Date: 2026-08-25
Target: World of Warcraft Retail 12.1.0 / Interface 120100
SavedVariables schema: 29

## Scope

This report covers static/syntax/package validation for the new DK Codex test branch. Live World of Warcraft behavior still requires the checklist in `TESTING_v1.3.0.md`.

## Codex validation targets

- dedicated `Codex.lua` loaded before `Core.lua`;
- Blood/Frost/Unholy Patch 12.1 guidance data;
- Overview / Stats & Gear / Rotation / Survival / Utility / Character Check pages;
- cross-spec browsing without specialization switching;
- live read-only Character Check;
- common enchant-slot inspection and empty-socket detection;
- stat snapshot guarded by accessible-value checks;
- utility known/talented inspection without spell casting;
- EN/ptBR interface/localization coverage;
- `/dkm codex` plus backward-compatible `/dkm guide`;
- schema 29 retained with defaults-only Codex preferences;
- all 1.2.x loadout/dungeon/spec safeguards retained.

## Live-client limitation

Static Lua parsing and source validators cannot prove item-link timing, all localized UI wrapping, or protected/secret-value behavior in every combat state. Run the live checklist before publishing 1.3.0 as a stable CurseForge Release.
