# DK Mentor 1.0.17

This build adds configurable combat-bar sizing and fixes Preview HUDs so it truly overrides combat-only visibility while arranging the interface.

## Configurable bar size and width

A new **Bar size...** button is available under **Settings > HUDs and layout**. DK Buffs, External Buffs, Debuffs, and Abilities can now be adjusted independently.

Each bar supports:

- **Size:** 70% to 160%, in 10% steps.
- **Icons per row:** configurable width before wrapping.
- Aura bars default to 5 icons per row and can be set from 3 to 10.
- The Ability bar defaults to 11 icons per row and can be set from 3 to 11.
- **Restore default sizes** resets only bar layout values; saved HUD positions remain untouched.

The Blizzard-managed AuraContainer layout is updated out of combat when its width changes. Additional aura rows continue growing upward.

## Preview HUDs bug fix

The existing visibility helper already treated Preview as an override, but the 120 ms combat-state heartbeat still had a direct out-of-combat hide path. With **Bars only in combat** enabled, that heartbeat could hide DK Buffs, External Buffs, Debuffs, and Abilities immediately after Preview tried to show them.

1.0.17 removes that conflicting path: when **Preview HUDs** is enabled, the heartbeat and combat-end cleanup no longer hide the combat bars.

Blizzard-managed aura bars also receive explicit preview placeholders. This matters when no aura is currently active: the user still sees the bar footprint, can drag it, and can judge its configured width/scale before combat.

## Reset behavior

**Reset HUD positions** now resets positions only. It no longer overwrites custom combat-bar scales. Full `/dkm reset` still restores the complete default frame layout, including combat-bar size and icons-per-row settings.
