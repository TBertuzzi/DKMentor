# DK Mentor 3.1.3 — Arthas / Bolvar portrait selector

DK Mentor 3.1.3 adds a configurable visual speaker to the animated Lich King commentary portrait introduced in 3.1.

## New
- Added a **Portrait character** setting with **Arthas** and **Bolvar** choices.
- Arthas uses the Icecrown Citadel Lich King creature model.
- Bolvar uses the in-client Bolvar-as-Lich-King creature model.
- The selected character is applied to the movable/scalable animated portrait whenever commentary is shown.
- The portrait title updates to match the selected character.
- Added `/dkm voice portrait arthas` and `/dkm voice portrait bolvar` shortcuts.
- Layout preset export/import now preserves the selected portrait character while remaining compatible with existing `DKM31` preset strings.

## Important scope
The new selector changes the **visual portrait only**. Commentary audio continues to use the existing Lich King voice resources already referenced by DK Mentor. No Blizzard models, textures, or audio files are bundled in the addon.

## Preserved from 3.1.2
- Animated talking portrait lifecycle.
- Preparation enchant-status fallback.
- Frost 2H and dual-wield Runeforge guidance by weapon hand.
- SBA-friendly Build Mentor.
- Layout preset import/export.

## Version
- DK Mentor: **3.1.3**
- Retail interface: **120100**
