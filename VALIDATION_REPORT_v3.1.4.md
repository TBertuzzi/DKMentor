# DK Mentor 3.1.4 — Validation Report

Date: 2026-09-01

## Result

`python3 scripts/validate.py` passed for **DK Mentor 3.1.4 / Retail interface 120100**.

## Focused 3.1.4 checks

- Layout Presets frame now uses `FULLSCREEN_DIALOG`, frame level `1400`, top-level behavior, mouse input and drag support.
- Opening Layout Presets explicitly re-applies the top modal strata/level and raises the frame when supported.
- Lich King Commentary portrait controls are aligned on one row; the character selector is anchored directly after the scale control.
- Bolvar portrait source now uses NPC **99456 (`The Lich King`)** instead of NPC 95942.
- Arthas/Bolvar preset persistence remains compatible with the existing `DKM31` format.
- `Core.lua` chunk-level local estimate remains **185**, below the validator safety ceiling of 190 and below WoW Lua's 200-local limit.

## Package checks

All four generated ZIP files passed archive integrity testing.

- Test / Release / CurseForge SHA-256: `7373bd7d4498f994b9074bd1083bd91ee66270a929784abd303322f00afe0ebc`
- GitHub SHA-256: `21a0d778a7bb73366a81779fe217b1c0d46d7d8ae05b2c010b33124bc2dc2369`

The game package contains one top-level `DKMentor` directory and 24 packaged entries/files according to the archive listing.

## Live-client limitation

Static validation cannot prove final frame layering, portrait framing, or creature-model animation behavior inside the live WoW client. Complete `TESTING_v3.1.4.md` before publishing.
