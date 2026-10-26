## DK Mentor 3.3.4 - Patch 12.1.5 Compatibility

- Fixed the **Mind Freeze interrupt alert/action glow** not reliably appearing on interruptible target casts after the 12.1.5 castbar/security changes.
- Hardened interrupt tracking around target-scoped spellcast events and the NeverSecret target `castBarID`; no combat automation was added.
- Updated Retail compatibility to **Patch 12.1.5 / Interface 120105**.
- Migrated remaining legacy item API fallbacks to current `C_Item` APIs for Gear/Advisor item names, icons, quality colors, counts and item spells.
- Updated general Valeera guidance to **Corrosive Bilespear + Dundun's Favor** for normal Delve presets.
- Kept the dedicated **Azta'rec / Nemesis** preset on Healer + Corrosive Bilespear + Soul-Cracking Dreamcatcher + Phantasmal Spore Toxin.
- Updated Unholy Blightfall guidance for the October 6 tuning: Blightfall now consumes **100% of remaining plague damage**.
- Added Patch 12.1.5 Labyrinth live-test coverage while retaining Blizzard's native Delve detector instead of hard-coded map workarounds.
- Marked Gear Mentor target freshness for Blood, Frost and Unholy as **REVIEW** pending the dedicated 12.1.5/Kith'ix item audit.
- No intentional combat-engine, Assisted Combat, Talent Tree, HUD, Survival Coach or Meta Pulse redesign.
