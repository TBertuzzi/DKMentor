# DK Mentor 1.0.20

## DK Resources HUD

This release adds a compact Death Knight resource HUD designed to sit with the existing combat bars. It shows all six Rune recharge states and Runic Power without automating combat decisions.

### What is new

- Six live Rune recharge segments for Blood, Frost, and Unholy.
- Runic Power status bar with numeric text when the value is readable.
- In restricted combat, secret Runic Power is forwarded directly to Blizzard's native StatusBar; the fill can remain live while the numeric text is hidden.
- Runes + Runic Power, Runes only, and Runic Power only display modes.
- 70%-160% independent resource-HUD scale.
- Saved position, HUD lock/unlock, Preview support, reset support, and Combat only / Always integration.
- New `/dkm resources` commands.

No existing DK Buffs whitelist/AuraContainer logic was replaced by this feature.
