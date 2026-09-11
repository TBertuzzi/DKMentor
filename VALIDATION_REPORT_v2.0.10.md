# DK Mentor 2.0.10 — Validation Report

Date: 2026-08-26
Target: World of Warcraft Retail / Interface 120100
SavedVariables schema: 30

## Automated validation

Passed:

- `python3 scripts/validate.py`
  - Result: `Validation passed: DK Mentor 2.0.10, Retail interface 120100`
- Lua syntax validation with `texluac -p` for:
  - `Localization.lua`
  - `Data.lua`
  - `Builds.lua`
  - `Guides.lua`
  - `Codex.lua`
  - `Voices.lua`
  - `Core.lua`
  - `MentorEngine.lua`
- `texlua tests/codex_smoke.lua`
  - Result: `DK Codex 2.0 smoke test passed`
- `texlua tests/mentor_engine_smoke.lua`
  - Result: `DK Mentor 2.0.10 MentorEngine smoke test passed`

## 2.0.10 release-candidate guards

Validated by the project validator:

- schema 30 migration guard exists;
- stale HUD anchor / coordinate / scale / opacity sanitization exists;
- one-time 2.0 release notice exists;
- `ShowMentorAlertPreview` exists;
- Adaptive DK Coach exposes Test Alerts and Reset Mentor settings;
- `/dkm mentor test|reset` handlers exist;
- help explicitly states that DK Mentor recommends actions and never casts abilities automatically;
- Midnight 12.1 forbidden combat-log APIs are not used at runtime.

## Midnight safety scan

No runtime Lua reference to `COMBAT_LOG_EVENT_UNFILTERED` or `CombatLogGetCurrentEventInfo` remains. The only CLEU text in the repository is the smoke-test assertion that intentionally fails if the event is ever registered again.

## Live release gate

Automated validation cannot replace in-client behavior checks. Complete `TESTING_v2.0.10.md` before promoting the CurseForge artifact to stable Release.
