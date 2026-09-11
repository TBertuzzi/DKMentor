# DK Mentor 2.0.11 — Localization hotfix

DK Mentor 2.0.11 fixes the manual addon-language override on clients whose WoW language differs from the language selected inside DK Mentor.

## Fixed

- Context selector labels now follow the selected DK Mentor language: **World / Delve / Dungeon / Mythic+ / Raid / PvP** or their ptBR equivalents.
- The compact DK Status HUD uses the same runtime-localized context labels.
- Header, Survival, Adaptive Coach, Build recommendation, and MentorEngine context titles use the runtime localization path.
- DK Mentor specialization labels (Blood / Frost / Unholy) now follow the addon language override instead of always inheriting the WoW client locale.
- Static Data, Builds, Guides, Codex, and Voices tables are re-localized after SavedVariables and the manual language override are available.
- Survival/Coach tags and descriptions are localized at render time, preventing stale ptBR text in an English addon UI (and vice versa).

## Why this happened

WoW addon files can execute before the addon's SavedVariables are guaranteed to be available. Some 2.0 static tables were therefore translated using the WoW client locale during file load. When the manual DK Mentor language was applied later, those cached strings stayed in the old language.

2.0.11 adds a reversible localization map and refreshes static module text after the selected language is known. Critical context/spec/coach keys also use runtime localization directly.

## Expected behavior

If WoW itself is ptBR and DK Mentor is set to English, DK Mentor-owned UI text will be English after `/reload`. Spell, item, aura, and ability names returned directly by Blizzard APIs can still appear in Portuguese because those names belong to the WoW client locale.

## Compatibility

- Retail / Midnight 12.1
- Interface 120100
- SavedVariables schema remains 30
- No combat logic changes from 2.0.10
