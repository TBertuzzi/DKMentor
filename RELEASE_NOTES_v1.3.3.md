# DK Mentor 1.3.3

## DK Codex navigation polish

This update focuses on the DK Codex navigation layout after live PT-BR testing showed long labels spilling into adjacent buttons.

### Improved

- The six Codex section buttons are now arranged in **two rows of three**.
- Section buttons are wider so labels such as **Atributos e equipamento** and **Verificação do personagem** remain inside their own controls.
- The Current / Blood / Frost / Unholy specialization selector remains unchanged on one row.
- The Codex content panel was moved down to make room for the second navigation row without increasing the main DK Mentor window size.
- Selected-state styling, scrolling, and all Codex content remain unchanged.

### Preserved

- Secret-safe Retail 12.1 aura-container handling from 1.3.2.
- DK Codex Character Check and all guide content.
- Loadouts 2.x, Dungeon/Mythic+ profiles, Loot Spec overrides, role-safe specialization switching, and compact HUD shortcuts.
- SavedVariables schema remains **29**; no database migration is required.
