# DK Mentor 3.2.0 — Validation Report

Date: 2026-09-06

## Result

**PASS — ready for live in-game testing.**

## 3.2 feature validation

- Stats & Folio Advisor is wired into the DK Codex and `/dkm advisor`.
- Live secondary-stat percentages/ratings and rating-based diminishing-return bands are present.
- Auto / PvE / PvP advisor context is persisted independently from real talent/spec state.
- Omnium Folio guidance exists for Blood, Frost, and Unholy PvE/PvP; live comparison is read-only and ambiguity falls back to NOT DETECTED rather than guessing.
- Gear Targets 2.0 includes per-spec Catalyst plans plus smart target/craft/tier tooltip annotations with EQUIPPED / OWNED / MISSING state.
- Advisor, Gear, and Build source metadata expose CURRENT / REVIEW PENDING status.
- DK Codex section navigation now uses native WoW icons, with spec-aware Builds/Rotation icons and no bundled artwork.
- Full Codex layout pass expands the main window/content width and uses dynamic text/card heights across all Equipment subviews.
- Advisor-specific visual pools are explicitly cleared before Gear Mentor rendering, preventing Folio/stat overlays after navigation.
- Build contexts/modes, Equipment subviews, and Stats & Folio context selectors now use compact native WoW icons while preserving localized labels.
- Frost and Unholy post-hotfix guidance was re-reviewed on 2026-09-06. Frost Mythic+ now explicitly excludes Frostbane from the recommended competitive direction; Unholy build direction remains stable; no third-party talent import strings were copied into the addon.
- Frost Preparation now matches current Wowhead potion/Runeforge direction, including a strict Fallen Crusader-only two-handed Ready Check.
- Existing 3.1.6 portrait, Preparation, SBA-friendly, preset, DK Ready combat-visibility, and Season 2 guidance behavior remains in the runtime package.

## Static/runtime validation

- `python3 scripts/validate.py`: **PASS**.
- Runtime Lua syntax checked with Lua 5.3 `texluac -p`: **15/15 PASS**.
- Static/data smoke tests executed with `texlua`: **18/18 PASS**.
- `Core.lua` chunk-level locals: **185**, below the project guard of 190 and WoW's 200-local ceiling.
- Retail interface: **120100**.
- Version metadata: **3.2.0** in TOC/Data.
- Runtime scan found no Midnight Cheat Sheet code/assets/talent strings and no new combat automation path.

## Package validation

- Test/runtime ZIP integrity: **PASS** (`unzip -t`).
- ZIP layout: exactly one top-level `DKMentor/` directory.
- Test/runtime SHA-256: `a4c051a37322b7a5352f908786e39daf14edccfcda127c3868b5b1389e98e88c`.

## Live-client checks still required

Offline/static validation cannot reproduce Retail's exact live `C_Traits` Omnium Folio state, tooltip lifecycle, protected/secret-value behavior, item-cache timing, or final frame layout at every UI scale. Complete `TESTING_v3.2.0.md` in WoW Retail before publishing 3.2.0.
