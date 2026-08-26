# Publishing DK Mentor 2.0.11

DK Mentor 2.0.11 is a focused localization hotfix on top of the stable 2.0.10 release. It does not change combat logic or SavedVariables schema.

## Release focus

- Make the manual Auto / Português / English setting authoritative for addon-owned UI text after `/reload`.
- Fix World / Delve / Dungeon / Mythic+ / Raid / PvP labels in the Combat page and compact DK Status HUD.
- Fix addon specialization labels and static Survival / Coach / Codex / Guide data that could be materialized before SavedVariables were available.
- Preserve WoW-client localization for spell/item names returned directly by Blizzard APIs.
- Preserve all 2.0.10 combat, Midnight Secret Value, HUD, Adaptive Coach, and schema-30 behavior.

## CurseForge package

Run `TESTING_v2.0.11.md`, especially the ptBR-client + English-addon scenario, then upload `DKMentor-v2.0.11-CurseForge.zip`.

Suggested display name: `DK Mentor 2.0.11`

Suggested release type: `Release`.
