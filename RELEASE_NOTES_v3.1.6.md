# DK Mentor 3.1.6 - Preparation, Presets & Lich King Portrait

DK Mentor 3.1.6 is the public 3.1 release for World of Warcraft Retail 12.1.0 / Midnight Season 2. It combines the full 3.1 feature set with the fixes and data refresh validated during the 3.1.0-3.1.6 test cycle.

## New in 3.1

- Added **Preparation / Ready Check** guidance for Death Knight Runeforges, common enchants, sockets/gems, consumables, and specialization-specific preparation.
- Added an optional **SBA-friendly** Build Mentor view for players who use Blizzard Assisted Combat. DK Mentor keeps defensives, interrupts, crowd control, utility, and situational decisions explicitly manual.
- Added **DKM31 layout preset export/import** for supported HUD positions and visual settings, including backward-compatible portrait position data.
- Added an optional **movable and scalable Lich King commentary portrait** using WoW-native resources. The portrait can show **Arthas or Bolvar** and animates during supported commentary playback.
- Added portrait-character persistence to presets and the `/dkm voice portrait arthas|bolvar` command.

## UI and live-test polish

- Added a localized **Close / Fechar** footer button to the Layout Presets window while keeping the standard top-right close button.
- Fixed Layout Presets layering so the modal stays above the main DK Mentor window and remains draggable.
- Reworked Lich King portrait position storage so the selected position survives hide/show, voice playback, scale changes, character switching, `/reload`, and DKM31 preset round-trips.
- Fixed locked portraits showing movement/preview helper text outside positioning mode.
- Synchronized portrait visibility/animation with the real sound handle when available, so the portrait stops promptly when commentary audio ends.
- Corrected the Bolvar option to use his in-client Lich King model.
- Reduced and compacted the main DK Mentor window while preserving access to all existing controls.
- The compact **DK Ready / DK Pronto** widget now hides automatically during combat and returns afterward when enabled.

## Season 2 guidance refresh - reviewed 2026-09-03

- Refreshed **Gear Mentor**, **Preparation**, and **DK Codex** data for Blood, Frost, and Unholy against current Patch 12.1 Season 2 guidance.
- **Frost:** refreshed dual-wield weapon direction, crafting/embellishment guidance, stat direction, consumables, and the Shattering Blade vs non-Shattering Blade Runeforge setup.
- **Unholy:** refreshed trinket target-count guidance, frequent-AoE alternatives, upgrade direction, stats, consumables, and crafting guidance.
- **Blood:** refreshed San'layn/Deathbringer Runeforge guidance plus current gem, enchant, and consumable direction.
- Gear recommendations remain advisory; close choices should still be simulated with tools such as Raidbots/Top Gear.

## Builds intentionally kept stable

Blizzard applied meaningful Frost tuning and an Unholy interaction fix on September 1. At the final 3.1.6 review, the relevant PvE/PvP talent-guide pages had not yet received a verified post-hotfix build refresh. Because of that, DK Mentor 3.1.6 intentionally **does not guess new talent trees, Hero Talent choices, or PvP builds**.

The current build data remains in place for 3.1.6. If the guide authors publish meaningful post-hotfix build changes, those can be handled cleanly in a later data release such as 3.2.

## Compatibility and safety

- World of Warcraft Retail interface: **120100**.
- Existing 3.1 portrait positions and older DKM31 preset strings remain backward compatible and migrate safely.
- Loadout automation remains the responsibility of **Loadout Pilot**; DK Mentor stays recommendation-focused.
- No Blizzard audio, model, or texture assets are bundled. The optional commentary portrait/audio references resources already installed by the WoW client.
- No third-party addon code or talent import strings are redistributed.

## Support

If DK Mentor is useful to you and you would like to support development:

https://buymeacoffee.com/bertuzzi

## Version

- DK Mentor: **3.1.6**
- Retail interface: **120100**
- Guidance review: **2026-09-03**
