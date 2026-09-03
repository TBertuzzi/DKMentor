# DK Mentor 3.1.4 — Portrait and preset UI polish

DK Mentor 3.1.4 is a focused live-test hotfix for three UI/model issues reported immediately after 3.1.3 testing.

## Fixed
- **Layout Presets modal:** now uses `FULLSCREEN_DIALOG`, a high frame level and top-level behavior so the preset editor stays visually and interactively above the main DK Mentor window. The window is also draggable.
- **Portrait controls:** Portrait ON/OFF, lock, scale and character selection now share one aligned row instead of placing the Arthas/Bolvar selector below the section.
- **Bolvar model:** the Bolvar option now loads NPC **99456 — The Lich King**, the in-client Bolvar Lich King form, instead of NPC 95942 (Bolvar without the Helm).

## Preserved
- Animated talking portrait lifecycle.
- Arthas/Bolvar selection and preset persistence.
- Preparation / Ready Check.
- SBA-friendly Build Mentor.
- Frost 2H and dual-wield Runeforge guidance.
- Layout preset import/export format remains `DKM31`.

## Version
- DK Mentor: **3.1.4**
- Retail interface: **120100**
