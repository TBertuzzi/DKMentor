# Validation Report - DK Mentor 1.3.2

Date: 2026-08-25
Target: World of Warcraft Retail 12.1.x / Interface 120100
SavedVariables schema: 29

## Fix verified statically

- Removed the 1.3.1 `AuraButton:HookScript("OnShow"/"OnHide")` visibility hooks.
- Removed `AuraButton:IsShown` / `IsVisible` presence probing from the managed-aura path.
- Managed AuraButtons are now used only for presentation setup inside Blizzard's `initializeFrame` callback.
- The Blizzard AuraContainer remains responsible for secure aura assignment and icon visibility.
- DK Mentor's decorative background/title is edit/preview-only for managed aura bars; locked runtime no longer needs to observe secret aura presence.
- HUD Preview/unlocked positioning behavior remains present.
- No SavedVariables schema migration was added.

## Automated checks

- `texluac -p` passed for Localization.lua, Data.lua, Builds.lua, Guides.lua, Codex.lua, Voices.lua, Core.lua, and the Codex smoke test.
- `python3 scripts/validate.py` passed for DK Mentor 1.3.2 / Interface 120100.
- `texlua tests/codex_smoke.lua` passed when run from the project root.
- Validator now rejects AuraButton visibility queries, retained AuraButton presence lists, and AuraButton script hooks in the managed-aura creation path.

## Live-client limitation

This environment cannot run the World of Warcraft Retail client. The reported 1.3.1 error is directly addressed by removing the forbidden script binding, but the 1.3.2 Test build should still be verified in live Retail 12.1 by exercising DK Buffs, External Buffs, and Debuffs through empty -> active -> empty transitions, including combat and an instance where aura information is secret.
