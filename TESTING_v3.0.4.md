# DK Mentor 3.0.4 — Live test checklist

## 1. Compact Mentor HUD

- Open Settings and enable HUD Preview.
- The Live Mentor preview should be visibly smaller than 3.0.3 while still showing action, spell, and timing text.
- The default layout should be Compact when no layout preference existed.
- The title, health/state line, Move hint, and close button must not overlap.
- All three preview cards must remain readable in PT-BR and English.

## 2. Dynamic width

- In normal play, verify that one or two live Mentor cards do not reserve the full three-card width.
- Three populated cards should still fit without overlap or clipping.
- Moving the HUD and re-locking HUDs must preserve its saved anchor.

## 3. Alert Studio

- Open Alert Studio.
- Cycle Coach layout through Compact -> Medium -> Large -> Compact.
- Verify the Live Mentor HUD changes immediately.
- Verify Scale +/- and Opacity +/- still work together with every layout preset.
- Preview selected alert should still hide Studio temporarily and return after about 4 seconds.

## 4. Regression

- Setup Wizard can still be reopened from Settings and `/dkm setup`.
- Test alerts / Preview DK Tools still return to the wizard after about 4 seconds.
- Resource HUD preview does not raise the old `NormalizeResourceVisibilityMode` nil error.
- No unsupported square/check-mark glyphs appear.
- Mind Freeze, Review/Timeline/Patterns, DK Tools, and Loadout Pilot handoff still work.
