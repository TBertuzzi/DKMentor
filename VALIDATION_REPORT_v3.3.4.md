# DK Mentor 3.3.4 - Final Validation Report

Status: **PASS - ready for publication**

Final validation: **2026-10-26**  
Baseline: **published DK Mentor 3.3.3**

## Scope

DK Mentor 3.3.4 is a focused Patch 12.1.5 compatibility/data refresh plus the live-tested interrupt-alert regression fix. It updates the Retail interface target, removes remaining legacy item API fallbacks, refreshes current general Valeera Curio guidance, corrects post-3.3.3 Blightfall wording, and marks the pre-refresh Gear target set for review.

## Automated validation

- `python3 scripts/validate.py`: **PASS**
- Lua syntax (`texluac -p`): **21/21 PASS**
- Full Lua smoke suite (`texlua`): **40/40 PASS**
- `patch_1215_334_smoke.lua`: **PASS**
- New `interrupt_1215_r2_smoke.lua`: **PASS**
- Runtime ZIP integrity (`unzip -t`): **PASS**
- Runtime ZIP root: exactly one top-level `DKMentor/` directory
- Packaged addon version: **3.3.4**
- Retail Interface: **120105**
- Live patch target: **12.1.5**
- Data review date: **2026-10-13**
- Final CurseForge runtime SHA-256: `3070a27967e6187a90a17771ba739b8b9a6c3c17954fda0526b6de13c702668f`
- Final runtime is byte-identical to the tested r2 archive; only the distribution filename changes.


## Interrupt regression coverage

- Target-scoped registration state is tracked for `UNIT_SPELLCAST_INTERRUPTIBLE` / `UNIT_SPELLCAST_NOT_INTERRUPTIBLE`.
- Core trusts the target-scoped event name before falling back to the Secret-safe cast API boolean.
- Mind Freeze action glow uses the same event-first interruptibility state.
- Mentor Coach no longer requires `castGUID` / `spellID` from interruptibility-event payloads.
- Active cast identity is recovered from the target cast API using NeverSecret `castBarID`.
- Dedicated `interrupt_1215_r2_smoke.lua` regression test added.

## Runtime diff versus Test r1 / final tested r2 delta

Only two runtime files change in r2:

- `Core.lua` - target-scoped interruptibility event authority for the Mind Freeze HUD/action glow.
- `MentorEngine.lua` - target-scoped interrupt event handling and cast identity recovery through `castBarID`.

All build data, gear data, Valeera data, localization, Talent Tree, Assisted Combat, Meta Pulse, Preparation, and layout files are byte-identical to Test r1.

## 12.1.5 compatibility coverage

Validated that runtime item lookups no longer depend on the removed legacy item globals covered by this migration and use current `C_Item` paths for item info, instant info, icons, quality colors, counts and item spells.

The existing Delve context path `C_PartyInfo.IsDelveInProgress()` remains present. Labyrinth behavior still requires a live-client check because this environment cannot enter the new content.

## Valeera coverage

- General utility Curio ordering now puts **Dundun's Favor** first.
- Auto, Safe, Balanced, Fast, High Tier and Leveling presets use **Corrosive Bilespear + Dundun's Favor** for Blood, Frost and Unholy.
- Nemesis/Azta'rec remains **Healer + Corrosive Bilespear + Soul-Cracking Dreamcatcher + Phantasmal Spore Toxin**.

## Unholy coverage

- Raid, Mythic+, Dungeon and Delve retain the current **San'layn / Blightfall** standard direction established in 3.3.3.
- Blightfall educational text now reflects **100% of remaining plague damage** after the October 6 tuning.
- Open World Rider direction remains unchanged.

## Gear boundary

GearData target lists are intentionally not rewritten in this compatibility build. Advisor freshness marks Blood/Frost/Unholy Gear as **REVIEW** pending the dedicated 12.1.5/Kith'ix target reconciliation.

## Runtime diff versus 3.3.3

Ten runtime files changed intentionally:

- `DKMentor.toc` - Interface 120105 and version 3.3.4
- `Data.lua` - version/interface/patch/data date
- `Codex.lua` - patch/review metadata
- `Core.lua` - current C_Item compatibility paths
- `Advisor.lua` - current C_Item instant-info path
- `Builds.lua` - 12.1.5 review metadata and Blightfall wording
- `Guides.lua` - current Blightfall 100% timing wording
- `AdvisorData.lua` - 12.1.5 metadata and Gear REVIEW freshness
- `ValeeraData.lua` - Dundun general baseline / Azta'rec exception
- `Localization.lua` - matching EN/pt-BR guidance strings

Unchanged runtime includes GearData item targets, PreparationData, MetaData/MetaProvider, TalentTree runtime, Valeera runtime engine, Meta runtime, DK Tools, Mentor Studio and voice data. `MentorEngine.lua` is intentionally changed for the interrupt-event hotfix.

## Release promotion

The tested r2 runtime is promoted unchanged to the final 3.3.4 CurseForge package. A final web/source review on **2026-10-26** found no newer Death Knight hotfix requiring runtime or build-guidance changes.
