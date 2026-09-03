# Validation Report — DK Mentor 1.3.1

Date: 2026-08-25
Target: World of Warcraft Retail 12.1.0 / Interface 120100
SavedVariables schema: 29

## Completed checks

- Confirmed `DKMentor.toc` and `Data.lua` both report version `1.3.1`.
- Parsed `Localization.lua`, `Data.lua`, `Builds.lua`, `Guides.lua`, `Codex.lua`, `Voices.lua`, and `Core.lua` successfully with `texluac -p`.
- Ran `scripts/validate.py` successfully.
- Ran the existing DK Codex Lua smoke test successfully with `texlua`.
- Confirmed managed aura buttons are registered by the Retail 12.1 `AuraContainer` initialization callback.
- Confirmed DK Buffs, External Buffs, and Debuffs derive empty/non-empty presentation only from Blizzard-owned aura-button visibility, not from protected aura identity/timing values.
- Confirmed empty managed-aura bars hide only their label/backdrop/border; the parent frame and Blizzard `AuraContainer` remain active so future auras can materialize immediately.
- Confirmed `OnShow` and `OnHide` hooks schedule a chrome refresh when Blizzard changes managed aura-button visibility.
- Confirmed HUD Preview and unlocked-HUD mode intentionally keep empty aura frames visible for positioning.
- Confirmed the legacy/fallback aura-rendering path still hides its frame when its active list is empty.
- Confirmed SavedVariables schema remains 29; no database migration was introduced.
- Preserved DK Codex, Loadouts 2.x, Loot Spec, Dungeon Overrides, role-safe specialization switching, Build HUD interactions, and DK Arcs regression guards.

## Package checks

- Test ZIP integrity passed.
- CurseForge ZIP integrity passed.
- CurseForge ZIP contains exactly one top-level `DKMentor` folder.
- CurseForge runtime contains `DKMentor.toc`, `Core.lua`, `Codex.lua`, and the complete DK Arc media set.

Test SHA-256: `b3386724f3aeb77dfb85d3f0075d55c609bd46e8471ab7dbc17c91c38440cf39`

CurseForge SHA-256: `f8664ea66991c281e48fc802cc4aa34edbd32da541281e40e610d0c78aad3e6d`

## Live-client limitation

Static validation cannot prove every secure `AuraContainer` transition in the live Retail client. Before publishing this development build, verify DK Buffs, External Buffs, and Debuffs through at least one empty -> active -> empty transition with HUDs locked, then repeat once with Preview/unlocked mode.
