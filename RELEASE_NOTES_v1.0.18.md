# DK Mentor 1.0.18

## Hotfix: DK Buffs and Preview HUDs

Version 1.0.17 introduced a Lua scope-order regression in the new preview/layout helpers. The helper `ClearTrackingCooldown` was declared later in the file as a local function, so earlier functions resolved that name as a global. At runtime it was nil.

That affected two paths:

- normal **DK Buffs** restoration (`RestoreManagedAuraRuntime` -> `HideTrackingSlots`);
- **Preview HUDs** placeholder rendering (`ShowManagedAuraPreview`).

1.0.18 moves the cooldown-reset helper before those managed-aura helpers, preserving the Blizzard `AuraContainer` implementation from 1.0.16 and all 1.0.17 bar sizing / icons-per-row controls.

No DK proc whitelist, Cooldown Manager profile, AuraContainer filter, or combat-only visibility behavior was intentionally removed in this hotfix.
