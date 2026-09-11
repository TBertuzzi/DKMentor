# DK Mentor 1.0.16 live test checklist

Focus: Retail Midnight 12.1 / Season 2 native aura tracking and combat-exit visibility.

## First check: the reported regression

1. Install 1.0.16 over 1.0.15 and `/reload`.
2. Confirm **Bars only in combat: ON** in Settings after migration.
3. Attack a training dummy until several Blizzard Tracked Buffs/Tracked Bars effects are active.
4. Compare **DK Buffs** with the relevant active class/proc icons in Blizzard's Cooldown Manager. The DK Mentor row should now populate from Blizzard's AuraContainer rather than remaining at one or two readable auras.
5. Leave combat. DK Buffs, External Buffs, Debuffs, Abilities, and the interrupt HUD must disappear immediately when combat-only mode is enabled.
6. Wait 1-2 seconds after combat and confirm none of those frames reappear.

## Frost

- Trigger Killing Machine and Rime repeatedly and confirm active icons appear/disappear with Blizzard's own aura engine.
- Verify Frostbane, Freezing Tempest, Icy Talons, Bonegrinder, Killing Streak, Chosen of Frostbrood, Pillar of Frost, and Breath windows when the current build can produce them.
- Compare against Wowhead's Frost Max Buff Tracking/Khazak-style active buff coverage.

## Unholy

- Verify Sudden Doom, Runic Corruption, Icy Talons, Lesser Ghoul, Forbidden Knowledge, Dark Transformation, and relevant San'layn states when talented.
- Compare the practical coverage with Taeznak/Luxthos Cooldown Manager tracking.

## Blood

- Verify Bone Shield, Hemostasis, Crimson Scourge, Dancing Rune Weapon, Vampiric Blood, and relevant San'layn states.
- With the Season 2 set, verify Blood Debt stacks and Relentless Rider's Strength can appear.
- Compare with Luxthos/Quick Start Cooldown Manager tracking.

## Layout

- More than five active tracked buffs must wrap to a second row upward.
- Confirm the row does not grow into a very long horizontal strip.
- Test HUD lock/unlock and Preview mode. Preview is intentionally allowed outside combat.

## Safety / compatibility

- Test solo, Delves, dungeon/raid combat, and PvP where practical.
- Confirm no `ADDON_ACTION_FORBIDDEN`, taint, or secret-value errors.
- Confirm DK Mentor never changes the player's Blizzard Cooldown Manager layout or casts abilities.
