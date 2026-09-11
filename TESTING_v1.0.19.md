# DK Mentor 1.0.19 live test checklist

1. Install 1.0.19 over 1.0.18 and `/reload`.
2. Set **Bars only in combat: ON**, **Preview HUDs: OFF**, and **HUDs: LOCKED**.
3. Enter combat on a training dummy. Confirm DK Buffs, External Buffs, Debuffs, and Abilities do not disappear merely because HUDs are locked.
4. Trigger Frost/Unholy/Blood buffs/procs and confirm **DK Buffs** still populates through the native Blizzard AuraContainer.
5. Leave combat and confirm combat-only bars hide normally.
6. Set **HUDs: UNLOCKED**, enter combat again, and confirm visual behavior is the same; the only difference should be that bars can be dragged out of combat and show the drag hint.
7. Lock the HUDs again and verify saved positions do not change.
8. Enable **Preview HUDs** while out of combat. Confirm all preview bars remain visible and movable regardless of the lock setting.
9. Disable Preview and enter combat once more to confirm live DK Buffs still update.
10. Change bar scale/icons-per-row, `/reload`, and repeat steps 2-6 to ensure layout settings remain independent of lock state.
