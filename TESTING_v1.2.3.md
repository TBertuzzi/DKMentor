# DK Mentor 1.2.3 - Live test checklist

1. Install 1.2.3 over the existing 1.2.2 folder without deleting `DKMentorDB`.
2. `/reload` and confirm there is no Lua error during database initialization.
3. Configure two contexts with different playing specializations, for example World = Frost and Delve/Dungeon = Unholy.
4. Change context out of combat and verify DK Mentor requests the specialization promptly once the client reports the new context.
5. Log/reload while the current context maps to a different specialization and verify the first profile attempt happens shortly after entering the world rather than several seconds later.
6. If WoW temporarily rejects a specialization switch, remain out of combat and verify DK Mentor retries the pending target instead of giving up permanently.
7. Verify Frost <-> Unholy remains allowed for DPS while Blood cross-role automation is still protected in grouped Dungeon/Mythic+/Raid/PvP content.
8. Left-click the Build HUD specialization icon and confirm the Blood/Frost/Unholy picker still opens.
9. Right-click the Build HUD body and confirm the DK Mentor main window opens/closes.
10. Right-click directly on the specialization icon and confirm the main window opens/closes rather than opening the spec picker.
11. Confirm the HUD still shows context, Build, Gear, and DK READY on one line.
12. Re-test Dungeon Overrides dropdown layering and Loot Spec once to ensure 1.2.1 behavior remains intact.
