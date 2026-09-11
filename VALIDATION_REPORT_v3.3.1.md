# DK Mentor 3.3.1 - Validation Report (Test r1)

Status: **PASS - ready for in-game verification**

## Scope

3.3.1 Test r1 is based on the user-provided published **3.3.0 / Source r11** baseline plus the September 11 DK/Valeera guidance refresh.

## Versioning correction

- The previously generated `3.3.0 Test r12` label was discarded because 3.3.0 is already published.
- The next patch version is **3.3.1**.
- This working package is **3.3.1 Test r1**.
- Historical 3.3.0 release documentation was restored from the attached Source r11 baseline rather than rewritten as new 3.3.1 functionality.

## Changes validated

- Dedicated Valeera Nemesis / Azta'rec preset for Blood, Frost, and Unholy.
- High Tier remains a generic Hard Delves preset.
- Unholy Preparation alternatives added from the current guide refresh.
- Unholy PvP Pet/Rider vs Disease/San'layn presentation corrected and source ambiguity disclosed.
- DK guidance review date advanced to 2026-09-11 without forcing unrelated gear/meta churn.
- Addon version metadata advanced from 3.3.0 to 3.3.1.

## Automated validation

- `scripts/validate.py`: **PASS**
- Runtime Lua syntax (`texluac -p`): **21/21 PASS**
- Smoke tests (`texlua`): **36/36 PASS**
- Retail Interface: `120100`
- Addon Version: `3.3.1`
- Live patch data target: `12.1.0`
- Data review date: `2026-09-11`

## Regression boundary

The patch does not intentionally change Visual Talent Tree behavior, Saved/Export/Clone, Meta Pulse, Gear Mentor, Stats/Folio, HUDs, Survival Coach, interrupt handling, Lich King commentary, or Character Check beyond the guidance-data changes documented for 3.3.1.

## Live-client validation still required

Before publication, verify in Retail:

1. Valeera Nemesis preset renders and persists correctly for all three DK specs.
2. Unholy Preparation displays the new alternatives without turning optional choices into Ready Check failures.
3. Unholy PvP shows Pet/Rider as Recommended and Disease/San'layn as Alternative with the ambiguity note.
4. pt-BR/English labels remain readable at the user's normal UI scale.
