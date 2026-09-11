# Validation report — DK Mentor 1.0.11

Target: World of Warcraft Retail 12.1.0 / Interface 120100

Static release validation verifies:

- TOC and `Data.version` match 1.0.11.
- Runtime context remains automatic-only and experimental War Mode code is absent.
- Existing secret-boolean regression guards remain present.
- The interrupt alert is display-only and no spell-casting, action-button, macro, targeting, or attack API is introduced.
- Target cast inspection does not compare `notInterruptible` directly; the value goes through the accessibility guard first.
- Proc tracking is sourced from Blizzard spell-activation overlay events and known player-owned DK buff IDs.
- DK Buff Bar wrapping is limited to five icons per row.
- CurseForge/Test packages contain one top-level `DKMentor` folder.

Live-client validation is still required for proc/event coverage and exact interrupt-alert behavior under Retail 12.1 combat secrecy, especially in PvP.
