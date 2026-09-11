# DK Mentor 3.0.10 — Validation Report

Date: 2026-08-30
Target: World of Warcraft Retail / Midnight 12.1.0
Interface: 120100

## Offline validation

PASS:

- `Localization.lua` parsed with `texluac -p`
- `Data.lua` parsed with `texluac -p`
- `Builds.lua` parsed with `texluac -p`
- `Guides.lua` parsed with `texluac -p`
- `GearData.lua` parsed with `texluac -p`
- `Codex.lua` parsed with `texluac -p`
- `Voices.lua` parsed with `texluac -p`
- `Core.lua` parsed with `texluac -p`
- `MentorEngine.lua` parsed with `texluac -p`
- `MentorReview.lua` parsed with `texluac -p`
- `DKTools.lua` parsed with `texluac -p`
- `MentorStudio.lua` parsed with `texluac -p`
- Codex smoke test
- Core UX smoke test
- Gear Mentor smoke test
- Interrupt enhancement regression smoke test
- Localization override smoke test
- MentorEngine smoke test
- Modal navigation smoke test
- Review smoke test
- Ordered Rune display smoke test
- Studio/Setup smoke test
- DK Tools smoke test
- `python3 scripts/validate.py`

Validator result:

`Validation passed: DK Mentor 3.0.10, Retail interface 120100`

## 3.0.10 regression coverage

The validator/smoke suite checks that:

- `GearData.lua` is loaded and packaged in the correct runtime order;
- Blood/Frost/Unholy Gear Mentor datasets exist for patch 12.1.0;
- the Codex exposes Gear Mentor Dashboard / Targets / Sources / Trinkets / Upgrade Plan;
- Gear Mentor remains read-only and does not introduce equipment automation APIs;
- Builds retain Hero Talent/focus metadata;
- Rune presentation sorts ready Runes left and recharging Runes by descending progress;
- prior Midnight safety, interrupt, Review, Studio, modal, action-bar coverage, and unsupported-glyph guards remain enabled.

## Live-client validation still required

Offline tests cannot prove:

- item ownership/cache behavior for every account/bank state;
- localized item-name availability before Blizzard item data finishes loading;
- exact Gear Mentor wrapping at every UI Scale;
- the visual Rune-order effect while rapidly spending/recharging Runes;
- protected/Secret Value behavior in live combat;
- action-bar glow/sound presentation under real encounter timing.

Complete `TESTING_v3.0.10.md` in the Retail client before publishing the release as stable.
