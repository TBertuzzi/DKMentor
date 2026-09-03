# DK Mentor 1.3.0 - Live test checklist

This is a future-update test build. Do not treat static validation as a replacement for a live Retail 12.1 client test.

1. Install 1.3.0 over 1.2.3 without deleting `DKMentorDB` and `/reload`.
2. Confirm there is no database migration/login Lua error and existing Loadout/Dungeon Override mappings remain intact.
3. Open DK Mentor and confirm the former Guide tab is now **DK Codex**.
4. Confirm the Current / Blood / Frost / Unholy selectors browse Codex data without actually changing specialization.
5. Confirm the six pages open correctly: Overview, Stats & Gear, Rotation, Survival, Utility, Character Check.
6. Scroll every Codex page in both English and ptBR; verify text wraps cleanly and the scroll child expands to the full content.
7. On Stats & Gear, verify Blood shows separate San'layn and Deathbringer stat guidance, Frost shows Crit > Haste > Mastery > Versatility, and Unholy shows Crit > Mastery > Haste > Versatility.
8. Verify Runeforge, gem, enchant, and consumable guidance appears for each spec.
9. Verify Overview shows Hero Talent explanations and DK Rune/Runic Power/Death Strike fundamentals.
10. Verify Rotation includes a cheat sheet, beginner opener, and cooldown guidance for all three specs.
11. Verify Survival and Utility sections render the universal and spec-specific guidance.
12. Open Character Check with the active spec selected and confirm mapped talents, mapped gear, Runeforge, and ghoul state match the existing Ready Check behavior.
13. Remove one normal permanent enchant temporarily and confirm Character Check reports the slot without changing DK READY semantics.
14. If an equipped item has an empty socket, verify Character Check reports it. Re-socket and reopen/update the Codex to confirm the warning clears after item data refreshes.
15. Compare the displayed Crit/Haste/Mastery/Versatility snapshot with the Character pane. If the client hides a value, DK Mentor should show `?` instead of guessing.
16. Select a Codex spec different from the active spec and confirm Character Check explains that live diagnostics use the active character while static guidance is still browsable for the selected spec.
17. Verify Utility shows known/talented DK utility and points players to the Ability Availability Bar for live cooldown state.
18. Verify `/dkm codex` opens the Codex and `/dkm guide` still works as an alias.
19. Re-test right-click Build HUD -> open/close DK Mentor and left-click spec icon -> manual spec selector.
20. Re-test one Dungeon Override including Loot Spec and one World <-> Delve/Dungeon specialization transition to confirm 1.2.x behavior did not regress.
