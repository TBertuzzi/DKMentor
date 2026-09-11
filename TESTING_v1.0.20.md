# DK Mentor 1.0.20 live-client test checklist

## Upgrade

- Install 1.0.20 over 1.0.19 without deleting `DKMentorDB`.
- `/reload` and confirm existing HUD positions/sizes remain intact.
- Confirm no Lua errors on login.

## DK Resources

- Test Blood, Frost, and Unholy.
- Spend Runes and confirm each of the six segments empties/fills as its Rune recharges.
- Generate and spend Runic Power and confirm the bar fill tracks the resource.
- Out of combat, confirm readable Runic Power shows `current / max`.
- In combat, confirm the HUD remains functional if the raw Runic Power number becomes secret; numeric text may intentionally disappear while the native bar fill remains live.
- In **HUD size...**, cycle **Runes + Runic Power -> Runes only -> Runic Power only -> Both** and verify layout.
- Test 70%, 100%, and 160% resource-HUD scale.
- Move the HUD while unlocked, lock HUDs, and confirm locking prevents movement but never hides the HUD.
- With **Bars only in combat: ON**, confirm DK Resources appears in combat and disappears after combat.
- Turn **Preview HUDs: ON** out of combat and confirm representative Rune/Runic-Power placeholders appear for positioning.
- Confirm Preview and position/layout changes are rejected during combat.
- `/reload` and verify resource enabled state, mode, scale, and position persist.

## Regression

- Verify DK Buffs still uses the native AuraContainer path and shows tracked Frost/Unholy/Blood procs.
- Verify DK Buffs, External Buffs, Debuffs, and Abilities still honor Combat only / Always, Preview, scaling, row width, and HUD lock.
- Verify HUD lock remains interaction-only.
- Verify `/dkm resources on|off`, `/dkm resources runes on|off`, and `/dkm resources power on|off`.
