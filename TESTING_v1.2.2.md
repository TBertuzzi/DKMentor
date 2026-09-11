# DK Mentor 1.2.2 - Live hotfix checklist

1. Install 1.2.2 directly over the failing 1.2.1/working 1.2.0 install without deleting `DKMentorDB`.
2. Run `/reload` and confirm `InitializeDatabase` completes with no Lua error.
3. Open **Loadouts** and confirm both **Dungeon** and **Mythic+** profiles appear.
4. Confirm the new Mythic+ talent and gear defaults were copied from the previous Dungeon mappings when no M+ mapping existed.
5. Open **Dungeon Overrides**, open an editor, and confirm every picker renders above the panel and is clickable.
6. Confirm Loot Specialization choices are available and changing a Loot Spec does not change the playing specialization.
7. Confirm the Build HUD stays one line and clicking its specialization icon still opens Blood/Frost/Unholy.
8. Enter a dungeon/M0/M+ if possible and confirm the same dungeon-specific override is reused and no Lua errors appear.
