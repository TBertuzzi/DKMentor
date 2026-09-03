# DK Mentor 3.0.4 — Compact Live Mentor HUD

DK Mentor 3.0.4 focuses on the Live Mentor presentation. The coaching content introduced in 3.0 remains intact, but the HUD no longer needs to occupy such a large block of the screen.

## Live Mentor layout redesign

- Added **Compact**, **Medium**, and **Large** layout presets.
- **Compact is the default** when no previous layout preference exists.
- Compact reduces card height, icon size, padding, header height, and border emphasis while keeping the action, spell name, and timing/reason text readable.
- The frame width adapts to the number of populated cards, so one or two live recommendations no longer reserve an empty three-card footprint.
- Health/state information now has a dedicated small header line instead of competing with the title.
- The movement hint is shortened to **Move / Mover** while HUD editing is unlocked.
- Alert Studio now includes a **Coach layout** control in addition to the existing Scale and Opacity controls.

## Preserved behavior

No coaching rules, Review scoring, DK Tools logic, Mind Freeze Secret-safe handling, or Loadout Pilot boundaries were changed. The 3.0.3 Settings and preview-return fixes remain intact.

SavedVariables schema remains **31** and Setup Wizard schema remains **301**.
