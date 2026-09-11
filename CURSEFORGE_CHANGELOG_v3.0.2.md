# DK Mentor 3.0.2 — Core UI & HUD Hotfix

- Fixed `UpdateResourceHUD` crashing when HUD Preview was opened because `NormalizeResourceVisibilityMode` was declared too late in `Core.lua`.
- Removed the unsupported Unicode check-mark glyph that could render as empty squares in the language picker, Character Check and utility rows.
- Replaced the remaining red Blizzard action-button template in DK Mentor with the addon's dark/cyan flat button style.
- Improved selected-state feedback for language and HUD toggle buttons.
- Widened the language picker for PT-BR labels.
- Renamed the static Combat reference section from Survival to **DK Toolkit** to make its role clearer.
- Essential Live Mentor is now urgent-only and hides when there is no urgent readable call, instead of duplicating the static DK Toolkit.
- HUD Preview remains populated for positioning and is now explicitly titled as a Live Mentor preview.
- Preserved the 3.0.1 Setup Wizard UX fixes, Review/Timeline/Patterns, DK Tools, Secret-safe Mind Freeze handling and Loadout Pilot boundary.
