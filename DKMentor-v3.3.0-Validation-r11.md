# DK Mentor 3.3.0 - Validation Report (Test r11)

Status: **PASS - ready for in-game UI testing**

## Scope

r11 is based directly on the user-provided **3.3.0 Source r10** and changes only the talent-tree action-button presentation plus its layout smoke coverage.

## UI fix

- Replaced TalentTree uses of Blizzard `UIPanelButtonTemplate` with the existing `DKM.CreateActionButton` style used by the rest of DK Mentor.
- Header actions now size from the rendered localized text width plus padding, with sensible minimum widths.
- Header buttons use a consistent 28 px height and 6 px gap.
- `Saved (N)` reflows the action row when its count changes.
- The title reserves the remaining space dynamically so localized buttons do not collide with it.
- Disabled Clone/Export/Save/Create states explicitly refresh through `DKM.StyleActionButton` after `SetEnabled`.
- Export and Saved subpanel buttons were moved to the same DK Mentor style as well, preventing the red Blizzard style from reappearing inside this feature.

## Automated validation

- `scripts/validate.py`: PASS
- Lua syntax (`texluac -p`): **21/21 PASS**
- Smoke tests (`texlua`): **36/36 PASS**
- Retail Interface: `120100`
- Addon Version: `3.3.0`

## Regression boundary

No r10 build-source/context-marker data, guide coverage, talent-ID matching, clone behavior, Meta/Archon data, Gear, Valeera, Preparation, HUD, or Lich King commentary logic was changed.

## Live-client validation still required

Final rendered width depends on the live WoW font metrics and UI scale. Verify the pt-BR header row in-game, especially `Clonar no WoW`, `Abrir Talentos`, and `Salvos (N)`.
