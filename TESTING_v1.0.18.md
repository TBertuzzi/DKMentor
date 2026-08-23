# DK Mentor 1.0.18 live test checklist

1. Install 1.0.18 over 1.0.17 and `/reload`.
2. Keep **Preview HUDs** OFF and **Bars only in combat** ON. Enter combat on a training dummy and confirm **DK Buffs** populates with active tracked DK buffs/procs.
3. Leave combat and confirm combat-only bars disappear.
4. While out of combat, enable **Preview HUDs**. Confirm DK Buffs, External Buffs, Debuffs, and Abilities remain visible with movable preview placeholders and no Lua error.
5. Disable Preview. Confirm placeholders disappear and the native DK Buffs `AuraContainer` is restored. Enter combat again and confirm live DK buffs still update.
6. Open **Bar size...**, change DK Buffs scale and icons-per-row, then repeat Preview ON/OFF and combat entry/exit. Confirm sizing persists and the live buff container still works.
7. Toggle Preview ON/OFF several times to catch state-restoration regressions.
