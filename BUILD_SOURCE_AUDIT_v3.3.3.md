# DK Mentor 3.3.3 Test r1 - Guidance Source Audit

**Reviewed:** 2026-09-26  
**Live patch target:** 12.1.0  
**Retail Interface:** 120100  
**Baseline:** published/tested DK Mentor 3.3.2

## Decision

A new patch is warranted because the post-September-22 Unholy PvE recommendation has now consolidated. This is a substantive recommendation change, not a reaction to a page timestamp.

## Unholy PvE - meaningful change

Current Wowhead Unholy talent content now marks:

- **San'layn: Single Target/Cleave - Best**
- **San'layn: Mythic+/Delves - Best**
- **Rider of the Apocalypse: Open World - Best**

The displayed Wowhead page update date still reads September 5. DK Mentor intentionally preserves that displayed source date but marks the recommendation current because the recommendation body itself was reverified on September 26.

Icy Veins' Unholy PvE changelog independently records September 23 changes that moved the recommended single-target Raid build to San'layn, updated recommended builds to Blightfall, and changed the default rotation selection to San'layn. Some body text on the page remains inconsistent, so DK Mentor uses current Wowhead content as the primary PvE recommendation source and treats Icy Veins as corroborating rotation/timing evidence.

### DK Mentor action

- Raid: San'layn/Blightfall -> Recommended; Rider -> Alternative.
- Mythic+: San'layn/Blightfall -> Recommended; Rider -> Alternative.
- Dungeon: derived San'layn Mythic+ direction -> Recommended; Rider -> Alternative.
- Delve: San'layn/Blightfall -> Recommended; Rider -> Alternative.
- Open World: Rider remains Recommended.
- Unholy build freshness moves from REVIEW PENDING to CURRENT.
- No full third-party import string is bundled; Raid remains Hero-only coverage and M+/Delves continue to use source-backed markers.

Sources:
- https://www.wowhead.com/guide/classes/death-knight/unholy/talent-builds-pve-dps
- https://www.icy-veins.com/wow/unholy-death-knight-pve-dps-spec-builds-talents
- https://www.icy-veins.com/wow/unholy-death-knight-pve-dps-rotation-cooldowns-abilities

## Unholy Blightfall timing

Current Icy Veins rotation guidance supports a compact San'layn/Blightfall timing note: build plague duration through Dark Transformation, align Soul Reaper during the window when available, consume with Blightfall just before Soul Reaper ends or near the end of Dark Transformation, and follow with Putrefy to restore diseases. The guide also calls for enough Lesser Ghoul setup for Soul Reaper.

DK Mentor adds this as educational guide text only; it does not attempt combat-state automation or hidden aura tracking.

## Unholy PvP - no ranking flip yet

The current Icy Veins Unholy PvP page remains dated August 10 and still predates Blizzard's September 22 San'layn-specific PvP tuning. The existing Pet/Disease ambiguity is therefore unresolved by a current guide.

### DK Mentor action

No ordering change:
- Pet/Rider remains provisional Recommended.
- Disease/San'layn remains Alternative.
- Freshness remains REVIEW PENDING.

Source:
- https://www.icy-veins.com/wow/unholy-death-knight-pvp-talents-and-builds

## Blood and Frost

No newer current talent recommendation was found that resolves the post-September-22 ranking question:

- Blood Wowhead talent page still shows September 21.
- Frost Wowhead talent page still shows September 5.

Their 3.3.2 REVIEW PENDING state remains appropriate. Frost's existing 2+ Frostscythe / 3+ Glacial Advance markers are retained.

Sources:
- https://www.wowhead.com/guide/classes/death-knight/blood/talent-builds-pve-tank
- https://www.wowhead.com/guide/classes/death-knight/frost/talent-builds-pve-dps

## Official Blizzard changes

The September 22 Death Knight tuning and September 23 Blightfall/Valeera hotfixes remain the relevant official changes behind this refresh. No newer Death Knight or Valeera official hotfix found in the September 24-26 review window requires a new runtime workaround or a separate preset change.

Sources:
- https://worldofwarcraft.blizzard.com/en-us/news/24296142/hotfixes-september-22-2026
- https://worldofwarcraft.blizzard.com/en-us/news/24296142/hotfixes-september-23-2026

## Gear, tier, crafting, stats and Preparation

The current Wowhead gear/stat pages were rechecked against the 3.3.2 data direction. No meaningful new target replacement was identified for Blood, Frost, or Unholy trinkets, crafts, tier/Catalyst planning, stat priority, runeforge, or consumable guidance. Existing 3.3.2 data is retained without churn.

## Valeera / Delves

The current Valeera/Delve guidance and Blizzard hotfix history were rechecked. No new source-backed change requires replacing the existing role, Curio, poison, Leveling, Hard Delve, or Nemesis/Azta'rec presets. The September 23 faction-change recovery note remains current.

## Meta Pulse boundary

Fresh Archon observations are consistent with the San'layn shift, especially in Mythic+ and High Keys, but 3.3.3 does not partially rewrite the built-in MetaData snapshot. That snapshot remains explicitly dated 2026-09-08. This avoids mixing a newly sampled Hero Talent percentage with stale DPS/weapon/sample fields from another capture window.

## Runtime scope

Expected intentional runtime changes:
- `DKMentor.toc`
- `Data.lua`
- `Builds.lua`
- `Guides.lua`
- `AdvisorData.lua`
- `Localization.lua`

No intended runtime changes to Core, Talent Tree, Meta runtime/provider, Gear, Preparation, Valeera, HUDs, combat engine, Mentor Review, or DK Tools.
