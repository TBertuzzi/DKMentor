# DK Mentor 1.2.1

Version 1.2.1 brings the dungeon/loadout lessons proven in Loadout Pilot back into DK Mentor and addresses the first community report around the 1.2.0 Dungeon Overrides UI.

## Dungeon and Mythic+ profiles

- **Dungeon** and **Mythic+** are now separate default profiles.
- A slotted keystone is detected before the Mythic+ timer starts so DK Mentor can prepare the M+ profile while the client still permits specialization/talent/equipment changes.
- Existing 1.2.0 Dungeon mappings seed the new Mythic+ defaults once during migration, so upgrading does not silently discard an established M+ setup.

## One override per dungeon

A dungeon-specific override is now shared across **Normal, Heroic, Mythic 0, and Mythic+**. DK Mentor resolves Challenge Mode maps to a stable dungeon InstanceID whenever possible and migrates older Challenge/instance/map keys into that canonical identity.

The override itself stays the same across difficulties, while fields left on **Inherit** use the default profile for the context actually being played: regular Dungeon or Mythic+.

## Loot Specialization

Each dungeon override can now independently choose:

- No override.
- Current specialization.
- Blood.
- Frost.
- Unholy.

Loot Specialization does **not** participate in Tank/DPS role protection because it does not change the specialization or role being played. For example, a Frost or Unholy DPS can intentionally select Blood loot without being switched to Blood.

When the dungeon Loot Spec override ends, DK Mentor restores the Loot Specialization that was active before the override session.

## UI and role-safety fixes

- Fixed Talent, Equipment, Specialization, and Loot Spec picker layering so the menus render above the Dungeon Overrides editor.
- Extended automatic specialization role protection to Dungeon, Mythic+, Raid, and PvP.
- If WoW does not expose an assigned group role, DK Mentor conservatively compares against the current specialization role.
- The compact one-line Build HUD is unchanged; clicking the specialization icon still opens the manual Blood/Frost/Unholy selector.
- The HUD tooltip now includes detected content/dungeon, current/target specialization, assigned role, Loot Spec, active dungeon override, and pending loadout state.
- Equipment AUTO now keeps a swap pending until WoW reports the mapped Equipment Set as actually equipped and retries transient out-of-combat failures, matching the recovery behavior proven in Loadout Pilot.

## Compatibility

- Retail interface: 12.1.0 / 120100.
- SavedVariables schema: 29.
- Existing 1.2.0 settings are migrated automatically; do not delete `DKMentorDB`.
