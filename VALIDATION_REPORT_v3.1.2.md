# Validation Report — DK Mentor 3.1.2

Date: 2026-09-01

## Validation
- `scripts/validate.py` passed for DK Mentor 3.1.2 / Retail interface 120100.
- All 13 runtime Lua files passed `loadfile` syntax compilation using the available Lua runtime.
- All 14 repository smoke tests passed.
- Core.lua chunk-level local-variable count remains **185**, below the project safety threshold of 190 and WoW's 200-local hard limit.

## 3.1.2 fixes reviewed
- Preparation enchant detection first uses the equipped item link and falls back to `C_TooltipInfo.GetInventoryItem` / `ItemEnchantmentPermanent`, preventing an indefinitely unresolved CHECKING state when the legacy equipped-item link is unavailable.
- Frost dual-wield Preparation renders an explicit **Main Hand** recommendation followed by **Off Hand**. Shattering Blade selects Razorice for Main Hand; otherwise the existing 12.1 dataset selects Stoneskin Gargoyle. Fallen Crusader remains the Off Hand recommendation.
- The optional Lich King PlayerModel uses animation **60** while commentary is playing and refreshes it while speaking because creature talking animations are not guaranteed to loop by themselves. It returns to idle when playback ends.

## Package checks
- CurseForge/Test/Release archives contain one top-level `DKMentor` folder.
- GitHub archive contains the full 3.1.2 source tree.
- No Blizzard `.ogg`, `.mp3`, or `.wav` audio files are bundled.
- ZIP integrity tests passed.

## Live-client note
This environment cannot launch the World of Warcraft client. The Lich King model animation, Midnight TooltipInfo fallback and exact equipped Runeforge state still need confirmation with the **3.1.2 Test** package in Retail 12.1.0 before publishing.
