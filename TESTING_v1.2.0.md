# DK Mentor 1.2.0 - Test checklist

## Upgrade / regression

1. Install 1.2.0 over an existing 1.1.x installation without deleting `DKMentorDB`.
2. `/reload` and confirm there are no Lua errors.
3. Confirm existing talent mappings, equipment mappings, HUD positions, DK Arcs, language, and other settings remain intact.
4. Confirm the compact Build HUD remains one line and clicking its specialization icon still opens the Blood/Frost/Unholy manual selector.

## Content specialization profiles

5. Open **Loadouts** and switch among World, Delve, Dungeon, Raid, and PvP profiles.
6. Confirm the **Profile spec** selector offers Do not change, Blood, Frost, and Unholy.
7. Leave a profile on **Do not change** and confirm entering that content does not force a specialization change.
8. Map Frost to one profile and Unholy to another, with **Spec AUTO** enabled, and confirm the requested switch is attempted only out of combat.
9. Disable **Spec AUTO** and confirm content changes no longer switch specialization.
10. Confirm Talents AUTO and Gear AUTO continue to work after the target specialization is active.

## Role protection

11. In a party with the assigned Damage role, configure a Dungeon profile/override for Blood and confirm DK Mentor skips the automatic DPS -> Tank switch and DK READY reports the specialization mismatch.
12. In a party with the Tank role, configure a Dungeon profile/override for Frost or Unholy and confirm the automatic Tank -> DPS switch is skipped.
13. Confirm Frost <-> Unholy automatic switching is allowed for a Damage role when WoW itself permits the specialization change.
14. Confirm clicking the Build HUD specialization icon still allows manual switching according to normal WoW restrictions.

## Dungeon Overrides

15. Open **Loadouts -> Dungeon overrides...** and confirm the dungeon list populates from the current Mythic+ catalog and/or visited dungeons.
16. Configure one dungeon with an explicit specialization, talent loadout, and gear set.
17. Enter that dungeon and confirm the override is matched and the Build HUD uses the dungeon name.
18. Configure another dungeon with **Keep current** for talents and confirm DK Mentor does not change talents there.
19. Configure **Keep current** for gear and confirm DK Mentor does not change equipment there.
20. Leave specialization on Dungeon default while overriding only talents; confirm the normal Dungeon specialization is inherited.
21. Delete an override and confirm the dungeon falls back to the normal Dungeon profile.
22. Disable an override and confirm the normal Dungeon profile is used without deleting the saved override.
23. While inside a dungeon, change that dungeon's override and confirm the active AUTO profile re-evaluates immediately.
24. If the same dungeon appears through a seasonal Challenge Mode ID and a previously visited instance ID, confirm the manager reuses the existing override instead of showing a duplicate configuration.

## Ready Check / lifecycle

25. Confirm DK READY includes specialization readiness when a profile explicitly requests another spec.
26. Enter combat with a pending profile change and confirm it waits until combat ends instead of producing a protected-action error.
27. Leave combat and confirm the pending specialization/talent/gear profile is retried.
28. Force or encounter a specialization-change rejection and confirm DK Mentor clears the pending state and reports that WoW did not allow the change.
29. Switch specs manually, zone between content types, start a Mythic+ dungeon, die/resurrect, and `/reload`; confirm no Lua errors or stuck pending state.
