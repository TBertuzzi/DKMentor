# DK Mentor 1.0.3 - Live Test Checklist

Use the **Test** package for several normal play sessions before publishing the CurseForge file.

## Install / persistence

- [ ] Install over the previous DK Mentor folder and log in without Lua errors.
- [ ] `/reload` preserves HUD positions, mappings, automation settings, and voice preferences.
- [ ] Log out/in preserves the same settings.

## Automatic context

- [ ] World selects the World mapping.
- [ ] Delve selects the Delve mapping.
- [ ] Dungeon selects the Dungeon mapping.
- [ ] Raid selects the Raid mapping.
- [ ] PvP selects the PvP mapping.
- [ ] Returning to World restores the World mapping.

## Talents

- [ ] Talents AUTO changes to the mapped saved WoW loadout out of combat.
- [ ] Blizzard's native talent dropdown follows the automatic change.
- [ ] `TALENTS QUEUED` clears after the saved loadout is selected.
- [ ] A change requested during combat waits and completes after combat.

## Equipment

- [ ] Equipment AUTO changes to the mapped Equipment Set out of combat.
- [ ] `GEAR QUEUED` clears when the set is equipped.
- [ ] Missing items/set are shown as a warning rather than reported as ready.

## DK Ready Check

- [ ] Build HUD shows `DK READY` when talents, equipment, Runeforge, and applicable ghoul state are correct.
- [ ] Hovering the Build HUD shows detailed readiness lines.
- [ ] `/dkm ready` matches the HUD/tooltip result.

## Runeforge Guard

- [ ] A valid DK Runeforge on the main hand is detected.
- [ ] Frost dual-wield checks both main hand and off hand.
- [ ] Removing/replacing a Runeforge changes Ready Check to not ready.
- [ ] Applying a Runeforge to an equipped weapon refreshes the status without a reload.
- [ ] A normal non-DK weapon enchant is not reported as a valid Runeforge.

## Unholy Ghoul Guard

- [ ] Unholy with the ghoul active reports ready.
- [ ] Dismissing/losing the ghoul reports the missing pet.
- [ ] Re-summoning the ghoul clears the warning immediately.
- [ ] Vehicle/taxi transitions do not leave a false persistent ghoul warning.
- [ ] Blood and Frost do not require a ghoul.

## Combat HUDs

- [ ] DK Buff Bar updates correctly in and out of combat.
- [ ] External Buffs remain visible/update correctly in combat.
- [ ] Debuffs remain visible/update correctly in combat.
- [ ] External Buffs and Debuffs wrap after five icons and grow upward.
- [ ] Ability Bar updates cooldown/availability without protected-action errors.
- [ ] Combat-only mode hides/shows the four configured bars at the correct times.

## UI / localization

- [ ] Settings labels do not overflow buttons in ptBR.
- [ ] Main footer is not clipped.
- [ ] Build HUD Ready Check line fits at the chosen UI scale.
- [ ] enUS/ptBR strings look correct.

## Fair-play / errors

- [ ] No action is cast or pressed by DK Mentor.
- [ ] No protected-action/taint errors appear during combat.
- [ ] No Lua errors occur during dungeon/raid/PvP transitions.


## Extra 1.0.3 visual checks

- Confirm the AddOns list shows an icon for DK Mentor.
- Confirm the Build HUD no longer has a large empty space on the right.


## Extra 1.0.3 visual check

- Confirm the Build HUD has no unused bottom gap in the normal state and expands cleanly if a line wraps.


## Extra 1.0.3 specialization checks

- Click the Build HUD specialization icon out of combat and confirm the Blood / Frost / Unholy selector opens.
- Confirm the current specialization is marked as current.
- Switch specialization and confirm the DK Mentor HUD, talents, equipment mappings, and Ready Check update.
- Enter combat and confirm the specialization selector cannot be used.
