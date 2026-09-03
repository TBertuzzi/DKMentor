# DK Mentor 3.0.1 — Validation Report

## Offline result

**PASS**

Validated against World of Warcraft Retail / Midnight interface `120100`.

## Checks completed

- All 11 runtime Lua files parsed successfully with `texluac -p`.
- `python3 scripts/validate.py` passed for DK Mentor 3.0.1.
- DK Codex smoke test passed.
- Manual-language override smoke test passed.
- Adaptive MentorEngine smoke test passed.
- Review / Timeline / Patterns smoke test passed.
- DK Tools smoke test passed.
- Alert Studio / Setup Wizard 3.0.1 smoke test passed.
- Validator includes regression guards for the 3.0.1 wizard layout, 2x2 grids, auto-advance, selected-state feedback, preview hiding/restoration, Alert Studio preview behavior, and removal of the old ambiguous footer action.
- Existing guards for Midnight Secret-safe interrupt presentation, no forbidden combat log usage, click-through resource arcs, explicit HUD edit sessions, localization, Review 3.0, DK Tools, and Loadout Pilot ownership boundary remain enabled.

## Live-client requirement

Offline validation cannot reproduce WoW font metrics at every UI scale, actual frame stacking, or every Midnight Secret Value/event transition. The 3.0.1 Test package should therefore be accepted in a live Retail 12.1 client before publishing.
