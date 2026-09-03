# DK Mentor 2.0.4 validation report

Date: 2026-08-25
Target: World of Warcraft Retail 12.1.0 / Interface 120100

## Automated validation

- `python3 scripts/validate.py` -> **PASS**
  - `Validation passed: DK Mentor 2.0.4, Retail interface 120100`
- `texluac -p` for every runtime Lua file -> **PASS**
- `texlua tests/codex_smoke.lua` -> **PASS**
  - `DK Codex 2.0 smoke test passed`

## Interrupt-alert regression checks

Confirmed in `Core.lua`:

- `UNIT_SPELLCAST_INTERRUPTIBLE` is treated as an authoritative positive signal for the current target.
- `UNIT_SPELLCAST_NOT_INTERRUPTIBLE` clears/suppresses the alert state.
- Interruptibility events are registered with target-scoped `RegisterUnitEvent` and a generic registration fallback.
- Cast transition refreshes run after 0.05s, 0.20s and 0.80s to cover event/combat/cast propagation timing.
- `UNIT_SPELLCAST_DELAYED`, `UNIT_SPELLCAST_CHANNEL_UPDATE`, `UNIT_SPELLCAST_EMPOWER_START`, and `UNIT_SPELLCAST_EMPOWER_STOP` are covered.
- Cast stop/fail/interrupted/success, target change, and non-interruptible transitions clear the latch.
- No combat automation API was introduced; Mind Freeze is never cast automatically.

## Preserved regressions

The project validator also confirms the 2.0 responsibility boundary, active-only Midnight aura behavior, compact status widget, Codex source-row sizing, and the 2.0.3 click-through resource arc guard.

## Live-client requirement

The remaining acceptance test must be performed in the WoW client because addon restrictions, secret values and spellcast event ordering cannot be fully reproduced by the offline validator. Follow `TESTING_v2.0.4.md` before publishing stable.
