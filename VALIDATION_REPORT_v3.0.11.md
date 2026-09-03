# DK Mentor 3.0.11 — Validation Report

Date: 2026-08-30
Target: World of Warcraft Retail / Midnight 12.1.0
Interface: 120100

## Offline validation

PASS:

- All runtime Lua files parsed with `texluac -p`.
- Codex smoke test.
- Core UX smoke test.
- Gear Mentor 3.0.11 visual/item-tooltip smoke test.
- Interrupt enhancement regression smoke test.
- Localization override smoke test.
- MentorEngine smoke test.
- Modal navigation smoke test.
- Review smoke test.
- Ordered Rune display smoke test.
- Studio/Setup smoke test.
- DK Tools smoke test.
- `python3 scripts/validate.py`.

Validator result:

`Validation passed: DK Mentor 3.0.11, Retail interface 120100`

## 3.0.11 regression coverage

The validator/smoke suite checks that:

- the Gear Mentor uses visual item rendering for the Stats/Gear section;
- item icons resolve through the WoW item API with a safe question-mark fallback;
- item cards retain EQUIPPED / OWNED / TARGET state;
- native WoW item hyperlinks are used for mouseover tooltips;
- Gear and Upgrades tab labels preserve the existing `targets` / `plan` saved keys;
- Sources and Trinkets retain the 3.0.10 data-driven target model;
- Gear Mentor remains advisory and does not add equipment automation APIs;
- 3.0.10 GearData, richer Builds, ordered Rune presentation, interrupts, Review, Studio and prior Midnight guards remain enabled.

## Live-client validation still required

Offline tests cannot prove:

- item icon/quality availability before Blizzard item data finishes loading;
- native item tooltip presentation for every uncached target;
- exact card wrapping at every UI Scale and localization setting;
- account/bank ownership visibility on the user's live account;
- protected/Secret Value behavior in real combat;
- visual Rune ordering under live spend/recharge timing.

Complete `TESTING_v3.0.11.md` in the Retail client before publishing the release as stable.
