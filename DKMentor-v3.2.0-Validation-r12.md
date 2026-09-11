# DK Mentor v3.2.0 — Validation r12

## Result
**PASS — ready for live in-game testing.**

## Scope
Valeera Season 2 live-guidance refresh on top of r11. No public version bump: the addon remains 3.2.0 while this test cycle is active.

## Implemented
- Added **Leveling** as a sixth Valeera preset without changing Auto / Safe / Balanced / Fast / High Tier.
- Leveling uses **Corrosive Bilespear + Dundun's Favor + Soulthirst Venom**.
- Preserved DK-specific role pairing: Blood = DPS; Frost/Unholy = Healer for the Leveling preset.
- Added a compact live-fix panel covering:
  - Sep 4: Mislaid Curiosity spawning repaired in The Darkway / Eggsplosive Growth.
  - Sep 1: Valeera XP from Mislaid Curiosities restored.
  - Aug 18: Dundun's Favor group-looting issue repaired.
  - Aug 17: Corrosive Bilespear higher-rank proc repaired.
  - Aug 21: Frostheart Venom / Phantasmal Spore Toxin cleanup on Delve exit repaired.
- Updated Valeera review date to 2026-09-06 and source metadata to include Blizzard.
- Preserved the general Bilespear + Soul-Cracking Dreamcatcher baseline for non-Leveling recommendations.
- Preserved r11 Frost/Unholy guidance changes, r9 Valeera native Blizzard configuration shortcut, and r10 HUD starter/reset layout fix.

## Automated validation
- `python3 scripts/validate.py`: **PASS**.
- Lua syntax with `texluac -p`: **PASS** for runtime and test Lua files.
- Complete smoke suite: **22/22 PASS**.
- Valeera-specific smoke coverage verifies 6 presets, Leveling mappings, newest live-hotfix metadata, and the native Blizzard configuration opener.
- Retail interface remains **120100**.
- Addon version remains **3.2.0**.

## Live-client checks still required
Offline validation cannot reproduce the final Retail UI scale, live localized tooltip resolution, current companion level/XP awards, or protected Blizzard companion-frame behavior in every combat state. Use `DKMentor-v3.2.0-Testing-r12.md` before release.
