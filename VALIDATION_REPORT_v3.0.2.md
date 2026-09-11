# DK Mentor 3.0.2 — Validation report

Validated offline on 2026-08-30 against the Retail / Midnight 12.1 interface target `120100`.

## Syntax

All runtime Lua files passed `texluac -p`:

- Localization.lua
- Data.lua
- Builds.lua
- Guides.lua
- Codex.lua
- Voices.lua
- Core.lua
- MentorEngine.lua
- MentorReview.lua
- DKTools.lua
- MentorStudio.lua

## Smoke tests

Passed:

- `tests/codex_smoke.lua`
- `tests/localization_smoke.lua`
- `tests/mentor_engine_smoke.lua`
- `tests/review_smoke.lua`
- `tests/tools_smoke.lua`
- `tests/studio_smoke.lua`
- `tests/core_ux_smoke.lua`

The new Core UX smoke guard verifies that the resource visibility normalizer is declared before `UpdateResourceHUD`, the unsupported check-mark glyph cannot return, Core uses the shared flat action-button factory, the language picker uses visual selection, the DK Toolkit label remains present, and Essential mode keeps the urgent-only/fallback-preview split.

## Static validator

`python3 scripts/validate.py`

Result:

`Validation passed: DK Mentor 3.0.2, Retail interface 120100`

## Runtime-specific acceptance still required

Offline tests cannot reproduce every WoW font, UI-scale, Secret Value, taint, combat-lockdown, frame-strata, or addon-skin interaction. Complete `TESTING_v3.0.2.md` in the live Retail client before promoting the build to stable.
