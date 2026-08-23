# Validation report — DK Mentor 1.0.9

Target: World of Warcraft Retail 12.1.0 / Interface 120100.

This build is intentionally based on the last known-good pre-War-Mode 1.0.3 source, with only version metadata and a narrow SavedVariables cleanup migration added. No War Mode UI, protected War Mode calls, War Mode events, or War Mode context remain in the runtime code.


## 1.0.9 context regression fix

Runtime context is automatic-only again. The build HUD follows the actual World/Delve/Dungeon/Raid/PvP environment, legacy manual overrides are cleared, and the War Mode experiment remains removed.
