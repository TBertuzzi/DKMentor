# DK Mentor 1.2.0

## Loadouts 2.0

DK Mentor can now manage a complete content profile made of **specialization + WoW talent loadout + WoW Equipment Set**.

### Content specialization profiles

Each World, Delve, Dungeon, Raid, and PvP profile can choose one of:

- Do not change specialization.
- Blood.
- Frost.
- Unholy.

`Do not change` preserves the previous DK Mentor behavior and uses the specialization you are currently playing.

Automatic specialization switching has its own global **Spec AUTO** toggle. Manual specialization switching from the compact Build HUD remains available by clicking the specialization icon.

### Role protection

When grouped in Dungeon or Raid content, DK Mentor checks the player's assigned group role before an automatic specialization change. An automatic DPS-to-Tank or Tank-to-DPS specialization change is skipped when it would conflict with the assigned role. Manual specialization switching is never blocked by this DK Mentor guard.

### Per-dungeon overrides

The Loadouts tab now includes **Dungeon Overrides**. Each discovered dungeon can independently override:

- Specialization.
- Talent loadout.
- Equipment Set.

Every component can also inherit the normal Dungeon profile or use **Keep current**, so an override can change only the exact pieces the player wants.

The dungeon catalog is discovered from WoW's Challenge Mode / Mythic+ APIs and visited instance IDs instead of shipping a hardcoded seasonal dungeon list. Existing overrides are matched across Challenge Mode, instance, and UI map IDs so a dungeon does not need to be configured twice when WoW exposes it through different identifiers. Changes to the override for the dungeon you are currently inside are applied immediately when the relevant AUTO option is enabled.

### Build HUD

The compact one-line Build HUD from 1.1.10 is preserved. In dungeons it can show the current dungeon name while keeping Build, Gear, DK READY, and the clickable specialization icon.

### Compatibility

- Retail interface: 12.1.0 / 120100.
- Existing 1.1.x talent and equipment mappings are preserved.
- Existing SavedVariables do not need to be deleted.
