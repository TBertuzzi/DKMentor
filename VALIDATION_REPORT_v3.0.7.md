# DK Mentor 3.0.7 — Validation Report

Date: 2026-08-30
Target: World of Warcraft Retail / Midnight 12.1
Interface: `120100`

## Source validation

- `python3 scripts/validate.py` — PASS
- All 11 runtime Lua files parsed with `texluac -p` — PASS
- DK Codex smoke test — PASS
- Localization override smoke test — PASS
- MentorEngine smoke test — PASS
- Review/Patterns smoke test — PASS
- DK Tools smoke test — PASS
- Alert Studio/Setup smoke test — PASS
- Core UX smoke test — PASS
- Modal navigation smoke test — PASS

## 3.0.7 regression coverage

Static guards verify that:

- Mentor Intelligence opens Alert Studio, Review, and Setup with itself as the explicit parent.
- Review stores/restores its caller and hides it while Review is visible.
- Alert Studio stores/restores its caller and suppresses parent restoration during temporary preview/child transitions.
- Setup stores/restores its caller, including Escape/close behavior, while temporary previews and Studio transitions do not prematurely restore the parent.
- Studio -> Review -> Studio -> Mentor Intelligence return order is preserved.
- Setup -> Studio -> Setup preserves the wizard step and original caller.
- Studio and Review use deterministic top-level `FULLSCREEN_DIALOG` frame levels.

## Safety

- No automatic spell casting or targeting APIs were added.
- Midnight Secret Value handling and combat restrictions are unchanged.
- SavedVariables schema remains `31`; Setup Wizard schema remains `301`.

Live WoW client testing is still required for final visual acceptance of frame visibility, Escape behavior, and frame-stack transitions.
