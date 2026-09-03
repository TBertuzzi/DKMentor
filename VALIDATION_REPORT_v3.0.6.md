# DK Mentor 3.0.6 — Validation report

Offline validation completed successfully for the 3.0.6 pinned Blizzard next-action update.

## Results

- `python3 scripts/validate.py` — PASS
- Runtime Lua syntax (`texluac -p`) — PASS for all 11 runtime Lua files
- `tests/codex_smoke.lua` — PASS
- `tests/core_ux_smoke.lua` — PASS
- `tests/localization_smoke.lua` — PASS
- `tests/mentor_engine_smoke.lua` — PASS
- `tests/review_smoke.lua` — PASS
- `tests/studio_smoke.lua` — PASS
- `tests/tools_smoke.lua` — PASS

## 3.0.6 regression coverage

- Card 1 uses `C_AssistedCombat.GetNextCastSpell(false)` when Next action is enabled.
- Blizzard next action remains in slot 1 while urgent defensive guidance continues in the remaining cards.
- Disabling Next action restores the prior Essential urgent-only behavior.
- Rotation card receives a dedicated subtle cyan presentation.
- Mentor Intelligence and Alert Studio expose the Next action toggle.
- `/dkm mentor nextaction on|off` is present.
- No custom casting, targeting, or protected-action automation was added.

Live WoW testing is still required for the real Assisted Combat recommendation stream and Midnight runtime behavior.
