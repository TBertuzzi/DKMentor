# DK Mentor 3.3.0 Test r12 - Guidance Source Audit

**Reviewed:** 2026-09-11  
**Live patch target:** 12.1.0  
**Retail Interface:** 120100  
**Baseline reviewed:** 3.3.0 Source r11

## Decision

A new source revision is warranted. The overall Death Knight PvE meta did **not** require a build/gear rewrite, but the audit found three meaningful data-quality changes:

1. A dedicated **Azta'rec / Nemesis** Valeera preset is needed instead of treating generic High Tier Delves and the Nemesis fight as the same recommendation.
2. Wowhead's **Unholy Enchants & Consumables** page was refreshed on 2026-09-10 and now exposes additional current alternatives missing from r11.
3. Icy Veins' current **Unholy PvP** page contains contradictory ranking text. DK Mentor now surfaces that ambiguity and treats Pet/Rider as the practical default because the explanatory text explicitly says Disease is currently weaker than Pet.

## Blizzard live changes since the r11 audit

### Blood - Grip of the Dead

Blizzard's September 9 hotfix fixed an issue where **Grip of the Dead** from Death and Decay could remain permanently active on targets.

**DK Mentor action:** reviewed. No runtime tracking or workaround in r11 depends on the buggy permanent state, so no combat-engine change is required.

Source: https://worldofwarcraft.blizzard.com/en-us/news/24296142/hotfixes-september-10-2026

### Unholy - Magus of the Dead

Blizzard's September 10 hotfix fixed **Magus of the Dead** occasionally spawning at extreme vertical differences.

**DK Mentor action:** reviewed. This is a summon-positioning bugfix, not a build/tuning change. No Build Mentor, Survival Coach, gear, or tier data needs to change.

Source: https://worldofwarcraft.blizzard.com/en-us/news/24296142/hotfixes-september-10-2026

### Patch 12.1.5

12.1.5 is still presented by Blizzard as the upcoming/PTR content update during this review window. DK Mentor remains targeted at live **12.1.0 / Interface 120100** for r12.

Source: https://worldofwarcraft.blizzard.com/en-us/news/24298589

## PvE Death Knight audit - Wowhead

### Blood

Reviewed current talent-build, Hero Talent, gear/BiS, trinket, crafting, tier and stat guidance. The r11 direction remains valid:

- Deathbringer remains the normal solo/Delve/dungeon/M+ direction used by DK Mentor.
- San'layn remains the raid-oriented recommendation/alternative where already represented.
- Gear targets, trinkets, crafting, tier-set interpretation and stat guidance do not require a new data direction.

Sources:
- https://www.wowhead.com/guide/classes/death-knight/blood/talent-builds-pve-tank
- https://www.wowhead.com/guide/classes/death-knight/blood/bis-gear-pve-tank
- https://www.wowhead.com/guide/classes/death-knight/blood/stat-priority-pve-tank

### Frost

Reviewed current talent-build, Hero Talent, gear/BiS, trinket, crafting, tier and stat guidance. The r11 direction remains valid:

- Deathbringer remains DK Mentor's primary current PvE direction for the represented contexts.
- Rider remains the represented alternative where appropriate.
- The September 1 Blizzard Frost tuning was already covered by the previous r11 audit.
- No current source change requires replacement of the existing Frost gear, tier or stat data.

Sources:
- https://www.wowhead.com/guide/classes/death-knight/frost/talent-builds-pve-dps
- https://www.wowhead.com/guide/classes/death-knight/frost/bis-gear-pve-dps
- https://www.wowhead.com/guide/classes/death-knight/frost/stat-priority-pve-dps

### Unholy

Reviewed current talent-build, Hero Talent, gear/BiS, trinket, crafting, tier and stat guidance. The r11 PvE build and GearData direction remains valid:

- Rider remains the straightforward/default direction represented for World/Delve/Dungeon/Mythic+/Raid where currently configured.
- San'layn remains a viable context alternative where already represented.
- The September 8 Unholy ring-target refresh already present in r11 remains current.
- No new BiS/trinket/crafting/tier/stat rewrite is required.

Sources:
- https://www.wowhead.com/guide/classes/death-knight/unholy/talent-builds-pve-dps
- https://www.wowhead.com/guide/classes/death-knight/unholy/bis-gear-pve-dps
- https://www.wowhead.com/guide/classes/death-knight/unholy/stat-priority-pve-dps

## Unholy consumables refresh - changed in r12

Wowhead updated the Unholy Enchants & Consumables guide on **2026-09-10**. r11 already contained the primary recommendations, but it did not expose all current alternatives.

Added to DK Mentor PreparationData:

- **Powerful Eversong Diamond** (item 240967) as a diamond alternative; Indecipherable Eversong Diamond remains recommended.
- **Flask of the Blood Knights** (item 241324) as a situational Haste alternative when personal stat balance makes Haste spike in value.
- **Refulgent Whetstone** (item 237371) for swords/axes as a weapon-buff alternative.
- **Refulgent Weightstone** (item 237369) for maces as a weapon-buff alternative.

Unchanged primary directions include Rune of the Apocalypse, Flask of the Magisters / Shattered Sun choice, Potion of Recklessness, Silvermoon Health Potion, Thalassian Phoenix Oil, Void-Touched Augment Rune, Silvermoon Parade / Royal Roast, and Masterful Garnet / Deadly Amethyst.

Source: https://www.wowhead.com/guide/classes/death-knight/unholy/enchants-gems-pve-dps

## PvP Death Knight audit - Icy Veins

### Frost

No meaningful new source change after the previous review. Rider remains the broad pressure/mobility direction and Deathbringer remains the concentrated burst alternative already modeled by DK Mentor.

Source: https://www.icy-veins.com/wow/frost-death-knight-pvp-talents-and-builds

### Unholy - corrected in r12

The current Icy Veins page is internally inconsistent:

- Its heading labels **Disease Build** as the "Best 3v3" setup.
- Its explanatory Disease section explicitly says the build is **currently weaker than the Pet build**.

r11 followed the heading and marked Disease/San'layn Recommended. r12 uses the more specific explanatory comparison:

- **Pet / Rider of the Apocalypse -> RECOMMENDED** practical default.
- **Disease / San'layn -> ALTERNATIVE** for rot pressure.
- The UI note explicitly warns that the source currently contains contradictory ranking text instead of hiding the uncertainty.

Source: https://www.icy-veins.com/wow/unholy-death-knight-pvp-talents-and-builds

## Valeera audit - changed in r12

The general Valeera companion direction remains valid: **Corrosive Bilespear + Soul-Cracking Dreamcatcher** continues to be the general Curio baseline represented by DK Mentor.

The r11 problem was the preset model, not a newly nerfed/buffed Curio. `High Tier` was labeled **Hard Delves / Nemesis**, but the current Azta'rec guide gives a boss-specific loadout that differs from the generic high-tier recommendations.

For **Azta'rec**, the guide recommends:

- Role: **Healer** (for poison dispel and sustain)
- Combat Curio: **Corrosive Bilespear**
- Utility Curio: **Soul-Cracking Dreamcatcher**
- Poison: **Phantasmal Spore Toxin** or **Soulthirst Venom**
- DPS Valeera only when the player has reliable dispel and self-healing

r12 therefore:

- Renames the existing `High Tier` short description to **Hard Delves**.
- Adds a dedicated **Nemesis / Azta'rec** preset.
- Uses Healer + Bilespear + Dreamcatcher + Phantasmal for Blood, Frost and Unholy.
- Mentions Soulthirst as the guide-approved poison alternative.

Source: https://www.icy-veins.com/wow/aztarec-delve-guide

No newer Valeera-specific Blizzard hotfix was found after the September 4 live-fix already represented in r11.

## Meta Pulse / Archon snapshot

Observed Hero Talent direction was rechecked. The broad guide-vs-logs classification remains stable; no spec flipped to a different practical Hero Talent direction that would justify rewriting the static snapshot. Because Archon data is dynamic and search/index captures can differ by hour/sample window, r12 intentionally does **not** churn the September 8 built-in MetaData snapshot from piecemeal captures.

## Files changed in r12

- `Data.lua`
- `Builds.lua`
- `PreparationData.lua`
- `ValeeraData.lua`
- `Core.lua`
- `Localization.lua`
- `scripts/validate.py`
- `tests/build_source_audit_330_smoke.lua`
- `tests/preparation_31_smoke.lua`
- `tests/valeera_320_smoke.lua`
- documentation/release notes

## Final recommendation

Ship **3.3.0 Test r12** for in-game verification. This is a guidance/data refresh, not a 3.4.0 feature release. Keep `Version: 3.3.0`, `Interface: 120100`, and live patch metadata at `12.1.0`.
