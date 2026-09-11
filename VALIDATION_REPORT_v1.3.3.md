# Validation Report - DK Mentor 1.3.3

Date: 2026-08-25
Target: World of Warcraft Retail 12.1.0 / Interface 120100
SavedVariables schema: 29

## Static checks

- Version metadata aligned to 1.3.3.
- Codex section navigation uses two rows of three 252px buttons.
- Long localized labels are constrained to the widened button label area.
- Codex content panel top offset moved from -101 to -133 while keeping the previous bottom edge.
- The old 119px six-button single-row layout is explicitly rejected by the validator.
- No SavedVariables schema change was introduced.
- 1.3.2 secret-aspect AuraContainer guards remain enabled.

## Live-client limitation

This environment cannot render the live World of Warcraft UI. Static checks can validate anchors, sizes, and Lua syntax, but final visual verification should be performed in Retail using PT-BR and English, especially the long Stats & Gear and Character Check labels.
