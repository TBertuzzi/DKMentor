# DK Mentor 2.0.6 validation report

Date: 2026-08-25
Retail interface: 120100
SavedVariables schema: 29

## Result

**PASS**

## Midnight load hotfix checks

- Runtime Lua contains no `COMBAT_LOG_EVENT_UNFILTERED` registration.
- Runtime Lua contains no `CombatLogGetCurrentEventInfo` call.
- Adaptive defensive pressure uses readable player-health deltas instead of combat-log damage parsing.
- Damage school is not inferred from health loss.
- Mind Freeze personal-interrupt tracking uses player `UNIT_SPELLCAST_SUCCEEDED` only while an active interrupt window exists.
- Target `UNIT_SPELLCAST_INTERRUPTED` can close/credit the tracked opportunity without CLEU.
- Blood Bone Shield refresh uses player-owned aura state.
- Restricted target aura state is never guessed during combat.
- Smoke test explicitly fails if MentorEngine attempts to register `COMBAT_LOG_EVENT_UNFILTERED` again.

## Regression checks

- 2.0 loadout automation boundary preserved.
- Compact DK status widget preserved.
- DK Codex source URL row fix preserved.
- Active-only aura HUD behavior preserved.
- Resource arc parent remains click-through.
- Mind Freeze target-scoped interruptibility events remain registered.
- Adaptive Coach / Combat Insights / DK Mentor Score remain present.
- CurseForge packaging still includes MentorEngine and the full Media folder.

## Automated checks

- `texluac -p` passed for Core.lua, MentorEngine.lua, Data.lua, Localization.lua, Codex.lua, Builds.lua, Guides.lua, and Voices.lua.
- `texlua tests/codex_smoke.lua` passed.
- `texlua tests/mentor_engine_smoke.lua` passed.
- `python3 scripts/validate.py` passed: `Validation passed: DK Mentor 2.0.6, Retail interface 120100`.

Live WoW verification is still required for the checklist in `TESTING_v2.0.6.md`.
