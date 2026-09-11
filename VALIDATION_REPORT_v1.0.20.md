# Validation Report - DK Mentor 1.0.20

- Version metadata synchronized with Retail Interface 120100.
- Added the DK Resources HUD with six Rune recharge segments and Runic Power display.
- Confirmed the resource HUD participates in Combat only / Always visibility, Preview, lock/unlock, saved position, reset, and independent 70%-160% scaling.
- Confirmed resource display mode can switch between Runes + Runic Power, Runes only, and Runic Power only outside combat.
- Confirmed Rune presentation uses `GetRuneCooldown` for indexes 1 through 6.
- Confirmed Runic Power is forwarded to native `StatusBar:SetMinMaxValues` / `SetValue` before any readable-only numeric formatting.
- Confirmed no Runic Power threshold/comparison logic is used to drive combat decisions.
- Confirmed numeric Runic Power text is emitted only after the value passes the addon's secret/accessibility guard.
- Confirmed Preview changes and HUD position resets are blocked during combat so resource widgets are not re-anchored after receiving restricted values.
- Confirmed the DK Buffs native AuraContainer path and the 1.0.19 interaction-only HUD lock regression guards remain present.
- All addon Lua files pass `texluac -p` syntax validation.
- `scripts/validate.py` passes all release and regression checks.

## Live-client limitation

This environment does not run the World of Warcraft client. Final Rune event timing, Runic Power secret-value rendering, and Blizzard 12.1 combat behavior must still be verified in the live client using `TESTING_v1.0.20.md`.
