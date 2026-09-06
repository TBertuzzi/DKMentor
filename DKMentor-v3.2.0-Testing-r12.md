# DK Mentor v3.2.0 — Testing r12

## Focus: Valeera live guidance refresh

This revision is based on r11 and preserves the Frost/Unholy guidance refresh, Valeera native configuration button, and r10 HUD starter-layout fix.

### New Leveling preset
1. Open `/dkm` -> **DK Codex** -> **Valeera**.
2. Confirm there are now six presets: Auto / Safe / Balanced / Fast / High Tier / Leveling.
3. Select **Leveling**.
4. Confirm every DK spec recommends **Corrosive Bilespear + Dundun's Favor + Soulthirst Venom**.
5. Blood should pair Leveling with DPS Valeera; Frost and Unholy should pair it with Healer Valeera.
6. Close/reopen the window and confirm the Leveling preset persists.

### Live-fix panel
Confirm the compact **Season 2 live fixes** block shows:
- The Darkway / Eggsplosive Growth Mislaid Curiosity spawn fix (Sep 4).
- Valeera XP from Mislaid Curiosities restored (Sep 1).
- Dundun's Favor group-looting fix (Aug 18).
- Corrosive Bilespear higher-rank proc issue fixed (Aug 17).
- Frostheart Venom / Phantasmal Spore Toxin cleanup fixed when leaving a Delve (Aug 21).

### Live Delve check
- Enter a Delve and confirm **DELVE ACTIVE**.
- Open Blizzard's Valeera setup from DK Mentor and verify the native panel still opens.
- If Valeera is below level 80, test a Mislaid Curiosity and confirm the game awards Valeera XP.
- If Dundun's Favor is equipped, confirm curiosity interaction/collection behaves normally.

### Regression
- Auto / Safe / Balanced / Fast / High Tier recommendations remain selectable.
- Valeera cards/icons/tooltips still fit at your normal UI scale.
- Switch Valeera -> Stats & Folio -> Equipment -> Builds -> Valeera and confirm no visual leakage.
- Reset HUDs still keeps Resources -> Abilities -> Coach -> aura bars separated.
- Frost Preparation/Runeforge behavior from r11 remains unchanged.
