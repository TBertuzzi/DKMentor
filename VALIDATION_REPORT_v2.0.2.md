# DK Mentor 2.0.2 - Validation Report

Date: 2026-08-25
Target: World of Warcraft Retail 12.1.x / Interface 120100
SavedVariables schema: 29

## Fix verified statically

- Managed DK Buffs, External Buffs, and Debuffs no longer restore decorative chrome merely because HUDs are unlocked.
- `UpdateManagedAuraBarChrome` now shows the background/title/drag hint only when explicit HUD Preview mode is enabled.
- Unlock mode still enables the transparent parent frame for dragging, while normal runtime remains visually active-only.
- Blizzard `AuraContainer` remains enabled and responsible for active aura icon visibility.
- No `AuraButton:IsShown` / `IsVisible` presence probing was added.
- No `AuraButton` `OnShow` / `OnHide` hooks were added, preserving the Retail 12.1 secret-aspect fix.
- The 2.0.1 compact DK Status HUD and PT-BR Codex source-action layout remain protected by validator regression checks.

## Automated checks

- `python3 scripts/validate.py` passed for DK Mentor 2.0.2 / Interface 120100.
- `texluac -p` passed for Localization.lua, Data.lua, Builds.lua, Guides.lua, Codex.lua, Voices.lua, Core.lua, and tests/codex_smoke.lua.
- `texlua tests/codex_smoke.lua` passed.
- Version consistency is 2.0.2 in DKMentor.toc, Data.lua, and the validator.

## Live-client limitation

Static validation cannot reproduce Blizzard's protected AuraContainer state in the live Retail client. Before public release, verify the empty -> active -> empty transitions from `TESTING_v2.0.2.md`, especially with HUDs unlocked and Preview OFF. The expected result is no empty black aura panel while unlocked; Preview ON should intentionally restore placeholders for positioning.
