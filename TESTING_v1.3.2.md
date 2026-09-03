# DK Mentor 1.3.2 - Live Test Checklist

Target: World of Warcraft Retail 12.1.x

1. Install over 1.3.1 without deleting `DKMentorDB`.
2. `/reload` and confirm no `HookScript ... blocked by secret aspects` error appears.
3. Keep HUDs locked and confirm an empty DK Buffs row leaves no black background/title panel.
4. Trigger a tracked DK proc/buff and confirm its Blizzard-managed icon appears.
5. Let the proc expire and confirm the icon disappears without a Lua error.
6. Repeat empty -> active -> empty for External Buffs.
7. Repeat empty -> active -> empty for Debuffs.
8. Enter combat and repeat the tests; there must be no AuraButton script/visibility errors.
9. Test inside a dungeon or Mythic+ where aura data is protected/secret.
10. Unlock HUDs and confirm the empty aura frames/titles reappear for dragging.
11. Enable HUD Preview and confirm placeholder aura bars are visible and movable.
12. Disable Preview / lock HUDs and confirm runtime returns to icon-only managed aura presentation.
13. Confirm Ability Bar behavior is unchanged.
14. Confirm DK Codex opens and switches browse specs without changing the player's actual specialization.
15. Confirm Loadouts/Dungeon Overrides still open and the specialization HUD left/right click behavior remains intact.
