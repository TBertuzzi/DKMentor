# DK Mentor 1.0.21 live-client test checklist

## Upgrade

- Install 1.0.21 over 1.0.20 without deleting `DKMentorDB`.
- `/reload` and confirm existing HUD positions, sizes, resource mode, and visibility settings remain intact.
- Confirm no Lua errors on login.

## HUD appearance

- Open **Settings -> HUD appearance...** out of combat.
- Test 30%, 60%, and 100% opacity on DK Buffs, External Buffs, Debuffs, Abilities, and DK Resources.
- `/reload` and confirm opacity persists for every HUD.
- Confirm opacity does not affect the **HUDs: LOCKED** visibility behavior; locked HUDs must remain visible when their normal visibility rules say they should be visible.
- Confirm Preview still overrides **Bars only in combat** while arranging the interface.
- Confirm size, opacity, icon-width, resource text, spacing, and reset controls are rejected during combat.

## DK Resources appearance

- Toggle **Power text: ON/OFF** and confirm both `Runic Power` and readable `current / max` text hide/show while the status-bar fill remains present.
- Cycle Rune spacing **Compact -> Normal -> Wide -> Compact** and verify all six segments remain aligned with the Runic Power bar.
- Verify the Settings resource summary updates when mode, text, or spacing changes.
- Change the resource position/scale/opacity/mode/text/spacing, then click **Restore DK Resources**.
- Confirm only DK Resources returns to its defaults; DK Buffs/External Buffs/Debuffs/Abilities must keep their positions and appearance.
- Confirm the resource enabled/disabled toggle is preserved by **Restore DK Resources**.

## Global appearance reset

- Customize several HUD sizes/opacities and icon counts.
- Click **Restore HUD appearance**.
- Confirm scale, opacity, and icon-row widths return to defaults without moving HUD positions.

## Regression

- Verify DK Buffs still uses the Blizzard AuraContainer path and shows tracked Blood/Frost/Unholy procs.
- Verify DK Buffs still behaves correctly with HUDs LOCKED and UNLOCKED.
- Verify combat-only exit hiding still works after Preview is turned off.
- Verify Runes still recharge normally and Runic Power fill remains functional in combat.
- Verify no combat-time logic branches on secret Runic Power values.
