# DK Mentor 3.0.17 — Validation Report

Validation passed: **DK Mentor 3.0.17**, Retail interface **120100**.

Static validation covered:
- version and required runtime files;
- visual Build Mentor renderer;
- Auto / World / Delve / Dungeon / Mythic+ / Raid / PvP selector;
- Blood, Frost, and Unholy profiles for all supported contexts;
- Hero Talent and key-talent spell icon/tooltip hooks;
- ptBR Build Mentor localization coverage;
- recommendation-only behavior and Loadout Pilot responsibility boundary;
- existing Gear Mentor, Codex navigation, rune, interrupt, and packaging regression guards.

Additional checks:
- all new build profile explanatory/focus/badge strings have ptBR localization entries;
- build profiles do not bundle talent import strings (`code = ""`);
- existing specialization-icon selector remains intact.

Live-client verification is still required for final visual spacing and WoW tooltip rendering under the player's UI scale.
