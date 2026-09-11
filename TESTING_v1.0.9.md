# DK Mentor 1.0.9 live test

- Reload/login with SavedVariables from 1.0.7 and confirm no Lua errors.
- Confirm HUD detects World, Delve, Dungeon, Raid, and PvP normally.
- Confirm there is no War Mode button/profile in DK Mentor.
- Confirm existing World/PvP/etc. talent and equipment mappings still work.
- Confirm specialization icon switcher, Ready Check, Runeforge/Ghoul guards, aura HUDs, and automatic talent/equipment switching still behave as before.


## 1.0.9 context regression fix

Runtime context is automatic-only again. The build HUD follows the actual World/Delve/Dungeon/Raid/PvP environment, legacy manual overrides are cleared, and the War Mode experiment remains removed.
