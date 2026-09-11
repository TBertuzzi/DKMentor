# DK Mentor 2.0.1 - Validation Report

Date: 2026-08-25
Retail interface: 120100

## Result

`python3 scripts/validate.py` passed for DK Mentor 2.0.1.

The validator confirms:

- TOC/Data version consistency for 2.0.1;
- the DK Mentor 2.0 loadout-automation boundary remains intact;
- DK Codex Builds still provides recommendation-only source/Loadout Pilot actions;
- the source URL action row uses the widened localized button layout;
- the DK Status HUD uses the 32px compact frame, 24px icon, reduced text gap, and dynamic text-sized width;
- DK Ready remains DK-specific;
- Midnight 12.1 managed-aura secret-aspect safeguards remain present;
- packaging scripts still include the complete Media folder.

## Live-client checks still required

Static validation cannot reproduce WoW font metrics, UI scale, or protected runtime behavior. Before public release, confirm the PT-BR button label, compact HUD spacing, drag persistence, manual specialization picker, and right-click behavior using `TESTING_v2.0.1.md` in the live Retail 12.1 client.
