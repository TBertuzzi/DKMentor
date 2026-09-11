# DK Mentor 3.0.2 — Core UI & HUD Hotfix

DK Mentor 3.0.2 is a focused stability and interface-polish release for the 3.0 branch.

## Fixed: Resource HUD preview crash

Opening HUD Preview could trigger:

`Core.lua:4170: attempt to call a nil value`

The resource visibility normalizer was declared after `UpdateResourceHUD`, so the earlier function resolved it as a nil global at runtime. The normalizer is now declared before every caller and the regression is guarded by validation.

## Fixed: unsupported square/check characters

The WoW font used by several DK Mentor panels does not reliably render the Unicode check-mark glyph. This could appear as an empty square in:

- Addon language selection;
- Character Check rows;
- Utility toolkit availability.

Language selection now uses the button's visual selected state instead of a glyph. Character Check uses the ASCII-safe `[OK]` marker.

## Unified DK Mentor button style

The remaining Blizzard `UIPanelButtonTemplate` action buttons have been replaced in the DK Mentor UI by the addon's own dark/cyan flat style.

This affects the main window, Settings, Combat actions, Character/Codex actions, Review, Alert Studio, Mentor settings and the Setup Wizard. Toggle buttons can now also visually highlight their active state instead of relying only on text.

## Language picker polish

The language picker is wider and no longer needs to squeeze `Português (Brasil)` beside a selection glyph. The selected language is indicated by the same cyan selected-state styling used elsewhere in DK Mentor.

## Live Mentor vs. DK Toolkit clarity

The static six-row combat reference is now labeled **DK Toolkit** rather than Survival. It is intentionally a complete spec/context reference list.

The Live Mentor has a different job: show what deserves attention now.

In **Essential** mode, the Live Mentor is now urgent-only. When there is no readable urgent defensive or interrupt call, the live Coach hides instead of filling itself with static fallback recommendations that duplicate the DK Toolkit.

HUD Preview remains useful: it can still populate example/fallback cards for positioning, but its title is explicitly shown as a **Live Mentor preview** so it cannot be mistaken for live Essential recommendations.

## Preserved behavior

- Setup Wizard 3.0.1 flow and 2x2 layouts remain intact.
- Midnight Secret-safe Mind Freeze handling remains unchanged.
- Review / Timeline / Patterns remain unchanged.
- DK Tools remain unchanged.
- Resource HUD click-through and edit-session safeguards remain unchanged.
- Loadout automation remains the responsibility of Loadout Pilot.
- SavedVariables schema remains **31**; Setup Wizard schema remains **301**.

## Compatibility

- World of Warcraft Retail
- Midnight 12.1.0
- Interface `120100`
