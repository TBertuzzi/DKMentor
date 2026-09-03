# DK Mentor 1.2.1 - Live test checklist

## Upgrade

1. Install 1.2.1 over 1.2.0 without deleting `DKMentorDB`.
2. Run `/reload` and confirm BugGrabber/BugSack reports no Lua errors.
3. Confirm existing HUD positions, DK Arcs, language, talent mappings, gear mappings, and Dungeon overrides remain intact.
4. Open **Loadouts** and confirm both **Dungeon** and **Mythic+** profiles are available.
5. On the first 1.2.1 load, confirm the new Mythic+ mapping initially mirrors the old 1.2.0 Dungeon mapping where no M+ mapping existed.

## Dungeon Overrides UI

6. Open **Loadouts -> Dungeon overrides** and open a dungeon editor.
7. Open the Talent picker and confirm it is completely above the editor and clickable.
8. Open the Equipment picker and confirm it is completely above the editor and clickable.
9. Open the Loot Specialization picker and confirm it is completely above the editor and clickable.
10. Close the editor and confirm no child picker remains orphaned on screen.

## Unified dungeon identity

11. Configure an override for a seasonal dungeon from the catalog.
12. Enter the same dungeon on Normal/Heroic/Mythic 0 and confirm the same override is recognized.
13. Enter/prepare the same dungeon with a keystone and confirm the same override is recognized instead of a duplicate M+ entry.
14. Confirm fields set to Inherit use the regular Dungeon default in M0 and the Mythic+ default when a keystone is slotted/active.
15. Confirm a slotted keystone changes the detected context to Mythic+ before the timer starts.

## Loot Specialization

16. While playing Frost or Unholy, configure a dungeon Loot Spec override for Blood and confirm only Loot Spec changes; the playing specialization/role does not change unless separately configured.
17. Set Loot Spec to **Current specialization** and confirm WoW reports current-spec loot behavior.
18. Set Loot Spec to **No override** and confirm DK Mentor leaves the current Loot Specialization untouched.
19. Enter a dungeon with an explicit Loot Spec override, then leave it; confirm the Loot Specialization active before entering is restored.
20. Change/remove the active dungeon Loot Spec override while inside the dungeon and confirm the rule re-evaluates without a Lua error.

## Role protection and sequencing

21. As assigned Damage, request Frost <-> Unholy automatically and confirm the same-role switch is allowed when WoW permits it.
22. As assigned Damage, request Blood as the playing specialization and confirm DK Mentor blocks the automatic Tank switch, but still applies an independent Blood Loot Spec override if configured.
23. As assigned Tank, request Frost/Unholy automatically and confirm the role-conflicting switch is blocked.
24. Confirm talents and equipment wait for the requested playing specialization to become active before their mappings apply.
25. Enter combat with pending changes, leave combat, and confirm supported changes retry without protected-action errors.
26. Trigger a transient equipment-set failure/transition if possible and confirm Gear AUTO remains pending until the mapped set is actually equipped, then clears without getting stuck.

## Regression

27. Confirm the Build HUD remains a single line and clicking its spec icon still opens the manual Blood/Frost/Unholy selector.
28. Test a PvP -> World transition and confirm the mapped World talents/gear recover.
29. Change the assigned group role and confirm DK Mentor re-evaluates the active rule.
30. Die/resurrect, zone, manually switch spec, and `/reload`; confirm no stuck Applying state or Lua errors.
