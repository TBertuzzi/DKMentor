# DK Mentor 1.3.2

## Secret-safe aura bar hotfix

This build fixes a Retail 12.1 secret-aspect error introduced by the first empty-aura-bar implementation in 1.3.1.

### Fixed

- Removed `OnShow` / `OnHide` hooks from Blizzard-owned AuraButtons.
- Removed AuraButton `IsShown`/visibility probing from DK Mentor.
- Prevents the live error: `Button:HookScript(): Cannot assign script handler for 'onshow' (blocked by secret aspects)`.

### Empty aura bars

Midnight 12.1 intentionally hides aura presence from addon Lua during protected states. DK Mentor therefore no longer tries to decide whether a Blizzard AuraButton is active.

- Blizzard's AuraContainer remains enabled and visible to its own secure engine.
- In normal locked gameplay DK Mentor hides the decorative background/title of DK Buffs, External Buffs, and Debuffs.
- Active aura icons still appear and disappear entirely under Blizzard control.
- If there are no matching auras, there are no icons and therefore no empty black panel.
- HUD Preview and unlocked mode still show the bar frame/title for positioning.

### Compatibility

- SavedVariables schema remains 29.
- No database migration is required.
- DK Codex, Loadouts 2.x, Dungeon Overrides, Loot Spec, faster specialization switching, role protection, DK Arcs, and existing settings are preserved.
