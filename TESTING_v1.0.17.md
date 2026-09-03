# DK Mentor 1.0.17 live test checklist

## Upgrade

1. Install 1.0.17 over 1.0.16 and `/reload`.
2. Confirm existing HUD positions are preserved.
3. Confirm the four combat bars retain their previous default sizes unless manually changed.

## Preview hard override

1. Enable **Bars only in combat**.
2. Leave combat and wait at least 2 seconds.
3. Enable **Preview HUDs**.
4. Confirm DK Buffs, External Buffs, Debuffs, and Abilities remain visible continuously outside combat.
5. Confirm empty AuraContainer bars show preview placeholders instead of disappearing.
6. Unlock HUDs and drag all four bars.
7. Disable Preview and confirm combat-only bars disappear again outside combat.

## Bar size and layout

For each of DK Buffs, External Buffs, Debuffs, and Abilities:

1. Open **Settings > Bar size...**.
2. Set Size to 70%, 100%, and 160%; verify the whole HUD scales accordingly.
3. Change icons per row down and up; verify bar width and wrapping update immediately in Preview.
4. Reload the UI and verify size, row width, and position persist.
5. Press **Restore default sizes** and verify size/row width reset without moving the bar.

## AuraContainer runtime

1. Disable Preview and enter combat.
2. Proc several DK buffs and verify the DK Buffs bar uses the selected width before wrapping upward.
3. Receive external buffs and several debuffs where possible; verify those managed bars use their configured row width.
4. Leave combat and confirm combat-only visibility still hides all bars.

## Ability bar

1. Set Ability icons per row to 3 or 5.
2. Enter combat and confirm abilities wrap into multiple rows without overlap.
3. Change back to 11 and confirm the default single-row layout returns.

## Regression checks

- Build HUD and Survival Coach behavior is unchanged.
- Mind Freeze interrupt alert behavior is unchanged.
- HUD lock/unlock still controls dragging.
- Preview does not cast abilities or perform protected combat actions.
- No Lua errors occur while changing size/layout out of combat.
- Bar-size controls refuse changes during combat lockdown.
