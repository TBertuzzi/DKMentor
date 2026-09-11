# DK Mentor v3.2.0 — Validation r8

## Result
**PASS — ready for live in-game testing.**

## New Valeera / Delve Mentor scope
- New first-class **Valeera** DK Codex section.
- Native WoW icons for menu, presets, roles, Curios, and Poisons.
- Five presets: Auto / Safe / Balanced / Fast / High Tier.
- Spec-aware DK Mentor pairings for Blood, Frost, and Unholy.
- Current Season 2 Curio baseline and all six Valeera Poison references included.
- `/dkm valeera` shortcut included.
- Recommendation-only: no automatic Valeera role/Curio/Poison writes were added.
- Valeera-specific visual pools are cleared when leaving the page to avoid cross-section UI leakage.

## Validation performed
- `python3 scripts/validate.py`: **PASS**.
- Runtime/test Lua syntax via `texluac -p`: **PASS**.
- Smoke tests via `texlua`: **19/19 PASS**.
- New `tests/valeera_320_smoke.lua` validates all presets, roles, Curio keys, Poison keys, and the default spec pairings.
- Retail interface remains **120100**.
- Addon version remains **3.2.0** because this is still the 3.2 live-test cycle.

## Live checks still required
The offline environment cannot validate final Retail tooltip availability, localized spell-name resolution for every Valeera Curio/Poison ID, Delve context detection in a real run, or the final card spacing at every WoW UI scale. Use the r8 test checklist before release.
