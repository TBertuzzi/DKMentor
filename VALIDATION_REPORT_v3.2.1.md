# DK Mentor 3.2.1 - Validation Report

## Result

**PASS - ready for publication.**

## Scope

Focused Unholy Gear Mentor ring-target refresh from the September 8, 2026 Wowhead Unholy BiS update.

## Data delta

- Added **Vile Alchemist's Band** (item 268249) as an Unholy Finger target, sourced from Vashnik / Venomous Abyss.
- Added **Sickening Signet of Atroxus** (item 252258) as an Unholy Finger target, sourced from Atroxus / Voidscar Arena.
- Updated Unholy gear source date to **2026-09-08**.
- Updated GearData review date to **2026-09-08**.
- Updated addon version to **3.2.1** and data version to **2026-09-08**.

## Regression boundary

Runtime comparison against the published DK Mentor 3.2.0 package shows only these files changed:

- `DKMentor.toc` - version only.
- `Data.lua` - addon/data version only.
- `GearData.lua` - Unholy ring targets and GearData dates only.

No intended changes were made to builds, Hero Talents, stats, trinkets, crafting, Catalyst plans, tier guidance, PvP, Valeera, Folio, Preparation, HUDs, layouts, commentary, or automation behavior.

## Validation

- `python3 scripts/validate.py`: **PASS**.
- Runtime Lua syntax (`texluac -p`): **PASS**.
- Smoke tests: **23/23 PASS**.
- Dedicated `unholy_gear_321_smoke.lua`: **PASS**.
- CurseForge ZIP integrity (`unzip -t`): **PASS**.
- Runtime ZIP layout: exactly one top-level `DKMentor/` directory.
- Retail interface: **120100**.
- Addon version: **3.2.1**.
