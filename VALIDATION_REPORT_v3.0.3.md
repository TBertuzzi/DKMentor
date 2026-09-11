# DK Mentor 3.0.3 — Validation report

Offline validation target: World of Warcraft Retail / Midnight 12.1.0 / Interface 120100.

Validation includes:

- Lua syntax for all runtime modules with `texluac -p`;
- project validator `scripts/validate.py`;
- Codex smoke test;
- localization override smoke test;
- MentorEngine smoke test;
- Review smoke test;
- DK Tools smoke test;
- Alert Studio / Setup smoke test;
- Core UX smoke test;
- static guards for four-second Setup preview return, compact single-line HUD labels, persistent Setup button, and subtle/debounced melee range hint;
- package parity checks for runtime files.

Live WoW testing is still required because offline tests cannot reproduce every UI scale/font behavior or Midnight Secret Value transition.
