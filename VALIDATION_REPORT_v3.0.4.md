# DK Mentor 3.0.4 — Validation report

Offline validation target: World of Warcraft Retail / Midnight 12.1.0 / Interface 120100.

Validation includes:

- Lua syntax for all 11 runtime modules with `texluac -p`;
- project validator `scripts/validate.py`;
- Codex smoke test;
- localization override smoke test;
- MentorEngine smoke test;
- Review smoke test;
- DK Tools smoke test;
- Alert Studio / Setup smoke test;
- Core UX smoke test;
- static guards for Compact / Medium / Large Mentor layouts, adaptive card width, compact movement label, Alert Studio layout selection, and preserved 3.0.x regressions;
- package parity checks for runtime files.

Offline result: **PASS**.

Live WoW testing is still required because offline tests cannot reproduce every UI scale/font behavior, tooltip interaction, or Midnight Secret Value transition.
