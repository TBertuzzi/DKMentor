# DK Mentor 2.0.2 - Release Notes

## Aura HUD cleanup restored

- Fixed the large empty **DK Buffs**, **External Buffs**, and **Debuffs** panels that could reappear merely because HUDs were unlocked.
- Unlocking HUDs now enables dragging only; it no longer forces the managed-aura background, title, or **Drag to move** text to stay visible.
- In normal gameplay, whether HUDs are locked or unlocked, Blizzard-managed aura bars remain visually active-only: when there is no matching aura, there is no empty black panel.
- **Preview HUDs** intentionally still shows the full placeholder/chrome so an empty aura bar can be found and positioned.
- The fix remains compatible with Midnight 12.1 secret-aspect restrictions: DK Mentor does not query AuraButton visibility and does not attach OnShow/OnHide hooks.

## Preserved from 2.0.1

- Compact DK Status HUD.
- Fixed PT-BR **Select source URL** action row.
- Recommendation-only DK Codex Builds and the Loadout Pilot handoff.
- No loadout automation inside DK Mentor.
- SavedVariables schema remains 29.
