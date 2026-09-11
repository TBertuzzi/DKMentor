# DK Mentor 2.0.7 validation report

## Scope

This hotfix tightens the resource arc HUD edit experience so the drag handle is never normal gameplay chrome.

## Verified behavior in code

- `hudLocked` defaults to locked and is forced locked when a fresh UI session initializes.
- `hudEditSessionActive` starts false and becomes true only after the player explicitly unlocks HUD movement in the current session.
- `CanMoveHUDs()` requires both the persisted lock flag to be false and the current-session edit flag to be true.
- Unknown or protected combat state is treated as non-movable.
- The resource arc parent remains permanently mouse-disabled/click-through.
- The small resource arc drag handle is shown and mouse-enabled only when `CanMoveHUDs()` returns true.
- Locking HUDs updates the handle immediately.

## Automated validation

- `python3 scripts/validate.py` passed: `Validation passed: DK Mentor 2.0.7, Retail interface 120100`.
- `texluac -p Core.lua MentorEngine.lua Data.lua Localization.lua` equivalent syntax checks passed per file.
- `texlua tests/codex_smoke.lua` passed: `DK Codex 2.0 smoke test passed`.
- `texlua tests/mentor_engine_smoke.lua` passed: `DK Mentor 2.0.7 MentorEngine smoke test passed`.

## Live test still required

Run `TESTING_v2.0.7.md` in the WoW client, especially reload-while-unlocked, explicit unlock/lock, and combat transitions.
