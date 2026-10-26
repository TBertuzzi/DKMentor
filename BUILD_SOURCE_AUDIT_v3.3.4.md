# DK Mentor 3.3.4 - Patch 12.1.5 Source Audit

**Data reviewed:** 2026-10-13  
**Interrupt hotfix reviewed:** 2026-10-20  
**Final release review:** 2026-10-26  
**Live patch target:** 12.1.5  
**Retail Interface:** 120105  
**Baseline:** published DK Mentor 3.3.3

## Decision

A compatibility patch is warranted. Patch 12.1.5 changes the Retail interface version and completes removal of several deprecated item API globals that DK Mentor 3.3.3 still retained as fallbacks. The same review also found a meaningful Valeera Curio recommendation change and a post-3.3.3 Blightfall tuning correction.


## Interrupt alert regression

Live 12.1.5 testing found the Mind Freeze interrupt prompt no longer appeared reliably. The underlying 3.3.4 r1 implementation was too dependent on restricted cast payload/API presentation ordering. Patch 12.1.5 also documents that castbar IDs are now unique per unit token; the target cast API continues to expose `castBarID` as NeverSecret.

### DK Mentor action

- Keep `RegisterUnitEvent(..., "target")` for the two interruptibility events and record whether target-scoped registration succeeded.
- When target-scoped, trust the **event name** as the interruptibility state instead of requiring readable payload fields.
- Give that event state priority for the Mind Freeze HUD and action glow; retain `SetAlphaFromBoolean` as the Secret-safe API fallback before the event arrives.
- In Mentor Coach, stop assuming interruptibility events include readable `castGUID` / `spellID`; resolve the active target cast through `UnitCastingInfo` / `UnitChannelInfo` and its NeverSecret `castBarID`.
- Add dedicated regression coverage so future patches cannot silently restore the payload dependency.

Sources:
- https://warcraft.wiki.gg/wiki/Patch_12.1.5/API_changes/notes
- https://warcraft.wiki.gg/wiki/API:UnitCastingInfo
- https://warcraft.wiki.gg/wiki/API:UnitChannelInfo

## Retail interface and API compatibility

Patch 12.1.5 uses Retail Interface **120105**. Warcraft Wiki's 12.1.5 API diff lists removal of legacy item globals including `GetItemInfo`, `GetItemInfoInstant`, `GetItemQualityColor`, `GetItemIcon`, `GetItemCount` and `GetItemSpell`, with current equivalents under `C_Item`.

### DK Mentor action

- Update `.toc`, `Data.lua` and Codex patch metadata to 12.1.5 / 120105.
- Remove remaining runtime fallbacks to the removed item globals.
- Use current `C_Item` paths only.

Sources:
- https://warcraft.wiki.gg/wiki/Patch_12.1.5
- https://warcraft.wiki.gg/wiki/Patch_12.1.5/API_changes

## Valeera - meaningful general Curio change

The current Icy Veins Valeera companion guide, refreshed October 10, now lists the same best Curio combination for all three roles:

- Corrosive Bilespear
- Dundun's Favor

The dedicated Azta'rec guide still recommends:

- Healer
- Corrosive Bilespear
- Soul-Cracking Dreamcatcher
- Phantasmal Spore Toxin or Soulthirst Venom

### DK Mentor action

- Promote Dundun's Favor to the general utility baseline.
- Update Auto/Safe/Balanced/Fast/High Tier/Leveling presets for all three DK specs.
- Keep Soul-Cracking Dreamcatcher for the Nemesis/Azta'rec preset.

Sources:
- https://www.icy-veins.com/wow/valeera-sanguinar-delve-companion-guide
- https://www.icy-veins.com/wow/aztarec-delve-guide

## Unholy - October 6 Blightfall tuning

Blizzard changed Blightfall to deal **100% of remaining plague damage (was 200%)** after the prior bug fix caused it to exceed the intended value. Current Unholy rotation guidance also describes the 100% value.

### DK Mentor action

- Keep the San'layn/Blightfall context ordering established in 3.3.3.
- Correct the educational wording to the current 100% value.
- Do not create an unsupported new target-count threshold.

Sources:
- https://worldofwarcraft.blizzard.com/en-us/news/24296142/hotfixes-august-31-2026
- https://www.icy-veins.com/wow/unholy-death-knight-pve-dps-rotation-cooldowns-abilities

## Labyrinth of Kindo'jan

12.1.5 introduces the Labyrinth as a mega-Delve experience with Valeera. No new documented addon-facing Labyrinth detector was found in the 12.1.5 API diff.

### DK Mentor action

Keep `C_PartyInfo.IsDelveInProgress()` as the primary detector and require live validation inside the Labyrinth. Do not hard-code speculative map IDs.

Sources:
- https://worldofwarcraft.blizzard.com/en-us/news/24304162/1215-content-update-notes
- https://www.icy-veins.com/wow/the-labyrinth-of-kindojan-guide

## Gear target boundary

12.1.5 adds new mid-season/Kith'ix loot and current gear guides have begun incorporating new targets. This release is not a full gear rebuild.

### DK Mentor action

- Keep existing item targets for continuity.
- Mark Blood/Frost/Unholy Gear freshness as REVIEW.
- Perform a dedicated live 12.1.5 gear audit before claiming fully current target lists.

## Intentionally unchanged

- Assisted Combat runtime and native SBA boundary.
- Visual Talent Tree read-only behavior and saved/create flow.
- HUD architecture and Survival Coach semantics.
- Meta Pulse provider architecture.
- Loadout Pilot boundary.


## Final release check - 2026-10-26

Blizzard hotfixes published through October 23 were rechecked before packaging. No newer Death Knight class hotfix was found that requires changing the tested 3.3.4 runtime or the current build guidance. Wowhead's current Unholy talent guide remains on the October 13 revision and continues to favor San'layn for Single Target/Cleave and Mythic+/Delves, with Rider retained for Open World. The final release therefore promotes the tested r2 runtime unchanged.
