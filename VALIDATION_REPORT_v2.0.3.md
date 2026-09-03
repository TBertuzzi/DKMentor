# DK Mentor 2.0.3 - Validation Report

Date: 2026-08-25
Target: World of Warcraft Retail 12.1.x / Interface 120100
SavedVariables schema: 29

## Fix verified statically

- The IceHUD-style Health / Runic Power arc parent remains 360x300 for layout, but is now permanently `EnableMouse(false)` so its transparent center cannot intercept world clicks.
- Arc repositioning moved to a dedicated 118x20 edit-only drag handle rather than making the entire transparent HUD draggable.
- The drag handle is enabled and shown only when `CanMoveHUDs()` is true: HUDs unlocked and player out of combat.
- `UpdateResourceHUD()` re-syncs the drag-handle state when combat begins, so entering combat while HUDs are unlocked immediately restores full click-through behavior.
- Saved arc position, Health, Runic Power, six Runes, scale, opacity, spacing, and power-text behavior are unchanged.
- 2.0.2 managed AuraContainer active-only behavior and Midnight 12.1 secret-aspect safeguards remain intact.

## Automated checks

- `python3 scripts/validate.py` passed for DK Mentor 2.0.3 / Interface 120100.
- `texluac -p` passed for Localization.lua, Data.lua, Builds.lua, Guides.lua, Codex.lua, Voices.lua, and Core.lua.
- `texluac tests/codex_smoke.lua` completed successfully.
- Version consistency is 2.0.3 in DKMentor.toc, Data.lua, and the validator.
- Validator regression guards now reject any return to `resourceArcFrame:EnableMouse(editing)` and require the dedicated click-through drag-handle implementation.

## Live-client limitation

Static validation cannot emulate WoW's 3D world targeting. Before public release, perform the click-through checks in `TESTING_v2.0.3.md`: place an enemy in the transparent center between the arcs, click it with HUDs locked, then repeat after entering combat with HUDs left unlocked. The expected result is that the world unit remains directly clickable in both cases.
