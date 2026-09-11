# DK Mentor 3.0.5 - Live Mentor Visual Hotfix

Version 3.0.5 fixes the visual regression introduced by the first compact Live Mentor layout and makes the HUD materially smaller without removing any coaching information.

## Fixed

- Restored the dark translucent DK Mentor card theme. The 3.0.4 layout routine was reapplying a `WHITE8X8` backdrop after Core had tinted the cards, which could reset the cards to opaque white in-game. Layout code no longer reapplies card backdrops.
- Compact now uses a substantially denser footprint: 96px frame height, 102x64 cards, 24px icons, 5px card gaps and tighter internal padding.
- Reduced header padding, movement-hint space and close-button size.
- Secondary timing/reason text is slightly softer so the action and ability remain the visual focus.
- Medium and Large presets were tightened as well, while remaining available through Alert Studio.

## Preserved

No coaching rules, Essential/Mentor/Training behavior, Review scoring, Patterns, DK Tools, interrupt handling, localization, Resource HUD logic or Loadout Pilot boundaries were changed.

SavedVariables schema remains 31 and Setup Wizard schema remains 301.
