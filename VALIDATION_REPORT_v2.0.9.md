# DK Mentor 2.0.9 validation report

Date: 2026-08-26
Retail interface: 120100

## Automated validation

- `python3 scripts/validate.py` — PASS
  - `Validation passed: DK Mentor 2.0.9, Retail interface 120100`
- `texluac -p` — PASS for `Localization.lua`, `Data.lua`, `Builds.lua`, `Guides.lua`, `Codex.lua`, `Voices.lua`, `Core.lua`, and `MentorEngine.lua`.
- `texlua tests/codex_smoke.lua` — PASS
  - `DK Codex 2.0 smoke test passed`
- `texlua tests/mentor_engine_smoke.lua` — PASS
  - `DK Mentor 2.0.9 MentorEngine smoke test passed`

## Interrupt regression guards

- Target cast presence is derived from the 12.x `castBarID` return, which is treated only as a readable cast-presence/identity value.
- The raw `notInterruptible` value is preserved even when Secret.
- Secret interruptibility is passed directly to `Frame:SetAlphaFromBoolean(notInterruptible, 0, 1)`; Lua does not branch on, negate, compare, stringify, or score the Secret boolean.
- The alert receives a lightweight 120 ms cast-state refresh in addition to cast events, preventing restricted event payloads from suppressing the visual.
- Readable interruptibility events remain transition fallbacks.
- The alert frame is mouse-disabled during normal gameplay and only becomes interactive during explicit HUD editing.
- `/dkm interrupt status` never prints the protected boolean itself; it reports only whether the state is readable, unavailable, or Secret-driven.

## Live-client requirement

A WoW client test is still required because Secret Value behavior cannot be fully emulated outside the game. Follow `TESTING_v2.0.9.md`, especially an interruptible enemy cast while in combat/restricted state.
