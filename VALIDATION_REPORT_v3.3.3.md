# DK Mentor 3.3.3 Test r1 - Validation Report

Status: **PASS - ready for live in-game verification**

## Scope

3.3.3 Test r1 is based on the published/tested **DK Mentor 3.3.2** source. The patch is intentionally narrow: it promotes the now-consolidated Unholy San'layn/Blightfall PvE direction and adds matching guide/freshness wording without changing combat/runtime engines.

## Validated guidance delta

- Unholy Open World keeps **Rider of the Apocalypse / Recommended**.
- Unholy Delves promotes **San'layn Blightfall / Recommended**; Rider becomes Alternative.
- Unholy Dungeon promotes **San'layn Blightfall / Recommended**; Rider becomes Alternative.
- Unholy Mythic+ promotes **San'layn Blightfall / Recommended**; Rider becomes Alternative.
- Unholy Raid/Single Target promotes **San'layn Blightfall / Recommended**; Rider becomes Alternative.
- Blightfall spell ID `1242616` is present in the current San'layn key-talent rows.
- Raid remains `hero-only`; DK Mentor does not claim a partial marker set is an exact full third-party talent import.
- Rider remains the Unholy SBA-friendly alternative.
- Unholy PvP remains Pet/Rider Recommended and Disease/San'layn Alternative with REVIEW PENDING.
- Blood and Frost PvE remain REVIEW PENDING.
- Valeera Nemesis/Azta'rec preset remains unchanged.
- Gear, Preparation, MetaData snapshot, and related runtime data remain unchanged.

## Automated validation

- `python3 scripts/validate.py`: **PASS**
- Lua syntax (`texluac -p`): **21/21 PASS**
- Full Lua smoke suite (`texlua`): **38/38 PASS**
- New `guidance_refresh_333_smoke.lua`: **PASS**
- Historical 3.3.1 / 3.3.2 guidance regression coverage: **PASS**
- Runtime ZIP integrity (`unzip -t`): **PASS**
- Runtime ZIP root: exactly one top-level `DKMentor/` directory
- Packaged TOC version: **3.3.3**
- Retail Interface: **120100**
- Live patch target: **12.1.0**
- Guidance review date: **2026-09-26**

## Runtime diff versus 3.3.2

Only these six runtime files changed intentionally:

- `DKMentor.toc` - version only
- `Data.lua` - addon/data version only
- `Builds.lua` - Unholy PvE ordering, notes, freshness, and review date
- `Guides.lua` - San'layn / Blightfall timing section
- `AdvisorData.lua` - Unholy PvE build freshness changes from Review to Current
- `Localization.lua` - EN/pt-BR strings for the new/updated guidance

Unchanged runtime includes `Core.lua`, `TalentTree.lua`, `Meta.lua`, `MetaProvider.lua`, `MetaData.lua`, `GearData.lua`, `PreparationData.lua`, `ValeeraData.lua`, `Valeera.lua`, `MentorEngine.lua`, `MentorReview.lua`, `DKTools.lua`, `MentorStudio.lua`, HUD behavior, Saved/Clone behavior, and commentary.

## Meta Pulse boundary

The built-in MetaData snapshot intentionally remains dated **2026-09-08**. It was not partially rewritten from mixed current samples because that would combine newly sampled Hero Talent percentages with stale DPS/weapon/sample fields. The 3.3.3 guide promotion is source-backed independently of that historical snapshot.

## Live-client validation still required

Before publication, verify in Retail:

1. Unholy Raid, Mythic+, Dungeon, and Delve show San'layn/Blightfall first as Recommended.
2. Rider remains visible as Alternative in those contexts and remains Recommended in Open World.
3. Blightfall/Soul Reaper/Putrefy guide wording fits in EN and pt-BR.
4. Visual Talent Tree switches cleanly between San'layn and Rider markers without claiming exact Raid coverage.
5. Unholy PvP still displays the provisional Pet/Rider vs Disease/San'layn ordering with REVIEW PENDING.
6. Blood/Frost REVIEW PENDING cards, Valeera, Gear Mentor, Preparation, Stats/Folio, Meta Pulse, HUDs, and Survival Coach render normally.
7. No Lua errors appear during login, spec/context switching, or Codex navigation.

## Result

**Automated result: PASS.** Test r1 is ready for the user's normal Retail in-game verification before final CurseForge packaging.
