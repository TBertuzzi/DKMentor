# DK Mentor 2.0.0 — Live Test Checklist

This is a major responsibility change. Static validation cannot replace testing inside World of Warcraft Retail 12.1.

## Upgrade safety

1. Install 2.0.0 over an existing 1.2.x/1.3.x DK Mentor with SavedVariables intact.
2. `/reload` and confirm there is no database/migration Lua error.
3. Confirm no specialization, talents, Equipment Set, or Loot Specialization changes happen automatically when changing World/Delve/Dungeon/M+/Raid/PvP context.
4. Confirm previous HUD positions/settings remain intact.

## Fresh-state safety

5. With a safe temporary backup/rename of SavedVariables, test a fresh DK Mentor 2.0 state and confirm the UI opens without missing-table errors. Restore the normal SavedVariables afterward if desired.

## Main UI

6. Confirm the main tabs are only Combat, DK Codex, and Settings.
7. Confirm no Loadouts tab, Dungeon Overrides button, Loot Spec controls, or talent/equipment mapping controls remain.
8. Confirm Settings shows the Loadout Pilot handoff section.

## Loadout Pilot handoff

9. With Loadout Pilot enabled, click **Open Loadout Pilot** and confirm it opens.
10. Test `/dkm loadouts` and `/dkm pilot` with Loadout Pilot enabled.
11. Disable Loadout Pilot, `/reload`, and confirm DK Mentor shows a clean "not detected" state without Lua errors.

## DK Status HUD

12. Confirm the widget shows only specialization icon + detected context + DK READY/NOT READY.
13. Left-click the specialization icon and confirm the manual Blood/Frost/Unholy picker still works.
14. Right-click the widget and confirm DK Mentor opens/closes.
15. Change content types and verify only the context text changes; there must be no automatic spec/talent/gear/loot action.

## DK Codex

16. Confirm the seven sections render correctly in PT-BR and English: Overview, Builds, Rotation, Survival, Stats & Gear, Utility, Character Check.
17. In Builds, browse Blood/Frost/Unholy and several content types; confirm recommendations/source URLs change appropriately and no WoW loadout is created/modified.
18. Confirm the Loadout Pilot button in Builds is enabled only when Loadout Pilot is detected.
19. Run Character Check and verify there is no talent-loadout/Equipment Set compliance row.

## DK Ready

20. Run `/dkm ready` on Frost/Blood and confirm the report is DK-specific.
21. Test Unholy with ghoul active/missing when practical.
22. Test equipped weapon Runeforge presence/missing when practical.

## Existing combat systems

23. Test DK Buffs, External Buffs, and Debuffs empty → active aura → empty; confirm no secret-aspect taint and no empty decorative chrome while locked.
24. Test Ability Bar, DK Resources Classic, DK Arcs, and Mind Freeze alert.
25. Test HUD lock/unlock/Preview, scale/opacity, combat-only visibility, language switch, and Lich King commentary settings.

Only promote 2.0.0 to the public default release after these live checks pass without Lua errors or unexpected automatic loadout behavior.
