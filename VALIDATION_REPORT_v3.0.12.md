# DK Mentor 3.0.12 — Validation Report

Date: 2026-08-30
Target: World of Warcraft Retail / Midnight 12.1.0
Interface: 120100

## Offline validation

PASS:

- All runtime Lua files parsed with `texluac -p`.
- Codex smoke test.
- Core UX smoke test.
- Gear Mentor 3.0.12 visual/tier/tooltip lifecycle smoke test.
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

`Validation passed: DK Mentor 3.0.12, Retail interface 120100`

## 3.0.12 regression coverage

The current suite checks that:

- the Season 2 DK set data contains item set 2055 and all five canonical class-set item IDs;
- the Gear Mentor exposes live tier-set state helpers and the five-piece visual strip;
- the Overview replaces the unclear Setup counter with Season 2 set progress;
- 2-piece / 4-piece bonus cards are present;
- item-card tooltips have normal `OnLeave` cleanup plus an ownership-aware `IsMouseOver` fallback;
- tooltip cleanup also runs when visual cards or the Gear Mentor hide;
- the new readability/localization strings are packaged;
- the Gear Mentor remains advisory and does not add equipment automation APIs;
- all 3.0.11 item-card behavior and earlier 3.0 systems remain guarded.

## Live-client validation still required

Offline tests cannot prove:

- whether the WoW client returns item-set metadata for every catalyzed/equipped item before item data finishes caching;
- exact tooltip disappearance timing in the live UI event loop;
- exact five-card tier-strip fit at every UI Scale;
- localized item/set names before Blizzard item data is cached;
- protected/Secret Value behavior in real combat.

Complete `TESTING_v3.0.12.md` in Retail before publishing as stable.
