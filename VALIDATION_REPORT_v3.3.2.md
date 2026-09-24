# DK Mentor 3.3.2 - Validation Report

**Status:** PASS - package is ready for live in-game verification  
**Validated:** 2026-09-24  
**Baseline:** published DK Mentor 3.3.1  
**Retail target:** World of Warcraft 12.1.0 / Interface 120100

## Scope

3.3.2 is a focused guidance/data refresh for the September 22 Death Knight tuning and September 23 hotfixes. It intentionally does not change the combat engine, HUDs, Survival Coach, Meta provider, native Talent Tree save/clone behavior, or Loadout Pilot integration.

## Automated validation

- `python3 scripts/validate.py`: **PASS** (`DK Mentor 3.3.2, Retail interface 120100`).
- Runtime Lua syntax with `texluac -p`: **21/21 PASS**.
- Smoke test suite with `texlua`: **37/37 PASS**.
- Dedicated `guidance_refresh_332_smoke.lua`: **PASS**.
- CurseForge ZIP integrity (`zip -T`): **PASS**.
- Runtime ZIP root: exactly one top-level `DKMentor/` directory.
- Packaged TOC version: **3.3.2**.
- Packaged Retail Interface: **120100**.

## 3.3.2 regression coverage

Validated that:

- Blood PvE source metadata is September 21 and its post-tuning build ranking is `review`.
- Frost PvE keeps the existing guide-backed Deathbringer/Rider direction and the four current Raid/Mythic+ context markers while its ranking is `review`.
- Frost PvP remains `current` because the September 22 Frostreaper/Obliterate buffs explicitly do not apply in PvP.
- Unholy Raid exposes Rider as the provisional Recommended profile plus the new San'layn Blightfall Alternative.
- The new Unholy San'layn raid profile does not claim a full exact guide import; Raid tree comparison stays Hero-only.
- Blightfall is represented on the current San'layn review profiles.
- Unholy PvP keeps Pet/Rider Recommended and Disease/San'layn Alternative while marking the stale pre-tuning source for review.
- Valeera's September 23 faction-change recovery hotfix is present without changing the existing Nemesis/Azta'rec preset.
- Gear, Preparation, and Advisor review dates advance to September 24 without replacing the already-current item, consumable, tier, or stat directions.

## Runtime diff boundary versus 3.3.1

Intended runtime/data changes are limited to:

- `DKMentor.toc`
- `Data.lua`
- `Builds.lua`
- `AdvisorData.lua`
- `GearData.lua`
- `PreparationData.lua`
- `ValeeraData.lua`
- `Localization.lua`

Validation/docs/tests also changed to cover the new review state and allow historical regression tests to keep validating older features while audit dates advance.

No intentional changes were made to `Core.lua`, `TalentTree.lua`, `Meta.lua`, `MetaData.lua`, `MetaProvider.lua`, `Advisor.lua`, `Valeera.lua`, `MentorEngine.lua`, `MentorReview.lua`, `DKTools.lua`, `MentorStudio.lua`, `Guides.lua`, `Codex.lua`, or `Voices.lua`.

## Live-client validation still required

This environment does not run the World of Warcraft Retail client. Before publication, follow `TESTING_v3.3.2.md` in-game, especially:

1. Verify the new REVIEW PENDING state and source dates render cleanly in EN and PT-BR.
2. Verify the new Unholy San'layn Blightfall raid Alternative renders without claiming an exact talent import.
3. Verify spell 1242616 resolves to the Blightfall icon/tooltip in the live client.
4. Verify the Valeera September 23 hotfix entry and the unchanged Nemesis preset.
5. Smoke HUDs, Talent Tree Saved/Export/Clone, Stats/Folio, Gear Mentor, Preparation, Meta Pulse, Survival Coach, and Loadout Pilot handoff.
