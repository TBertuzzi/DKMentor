# DK Mentor 2.0.11

- Fixed manual addon language selection not being respected by World/Delve/Dungeon/Mythic+/Raid/PvP context labels.
- Fixed the compact DK Status HUD keeping ptBR context names when DK Mentor was set to English.
- Fixed stale-language static Survival/Coach/Codex/Guide text caused by those tables loading before SavedVariables language settings were available.
- DK Mentor specialization labels now follow the addon language override.
- WoW-provided spell/item names still follow the WoW client language by design.
- Added localization regression coverage.
- No combat logic or SavedVariables schema changes; all 2.0.10 Midnight/HUD/Coach behavior is preserved.
