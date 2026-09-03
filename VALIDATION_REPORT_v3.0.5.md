# DK Mentor 3.0.5 - Validation report

## Automated validation

- `python3 scripts/validate.py`: PASS
- Runtime Lua syntax (`texluac -p`) for all 11 runtime Lua files: PASS
- Codex smoke test: PASS
- Localization override smoke test: PASS
- MentorEngine smoke test: PASS
- Review smoke test: PASS
- DK Tools smoke test: PASS
- Alert Studio / Setup Wizard smoke test: PASS
- Core UX smoke test: PASS

## 3.0.5 visual regression guards

- Compact layout is 96px high with 102x64 cards and 24px icons.
- Layout code is forbidden from calling `card:SetBackdrop(...)`; this prevents the 3.0.4 opaque-white card regression.
- Core creates the cards once with the dark DK Mentor backdrop and subtle cyan border.
- Secondary timing/reason text uses the smaller disabled-font style and reduced contrast.

## Live-client limitation

Offline validation cannot reproduce WoW UI scale, font rasterization, Secret Values, or the exact rendered appearance of frames in the Retail client. Live 12.1 testing is still required before publication.
