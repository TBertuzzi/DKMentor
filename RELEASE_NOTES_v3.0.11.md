# DK Mentor 3.0.11 — Visual Gear Mentor

DK Mentor 3.0.11 keeps the Season 2 gearing data introduced in 3.0.10, but completely changes how the Gear Mentor presents it.

## Visual item-first layout

The Gear Mentor no longer leads with long report-style text. The interface now centers on the actual recommended items:

- real WoW item icons;
- item-quality colored icon borders when item data is available;
- compact `EQUIPPED`, `OWNED`, and `TARGET` states;
- slot and priority visible directly on each card;
- full native WoW item tooltip on mouseover;
- source, priority, slot, and DK Mentor recommendation context appended to the tooltip.

The tooltip is generated from the real item ID, so Blizzard's normal localized item information remains the source of item stats and effects.

## Overview

The Gear Mentor Overview now starts with four compact live cards:

- Item level;
- Runeforge status;
- headline target progress;
- setup review status for enchants/sockets/item-data availability.

Below that, the current spec's headline gear targets are shown as visual item cards, followed by a compact stat-direction panel and the character's current Crit/Haste/Mastery/Versatility snapshot.

## Gear / Sources / Trinkets / Upgrades

- **Gear** — visual two-column item target grid.
- **Sources** — groups the same item cards under their current farming source.
- **Trinkets** — puts tracked trinket items first, with only short supporting guidance below.
- **Upgrades** — keeps crafting and Crest guidance in two compact columns instead of a long vertical report.

The internal saved view keys are unchanged, so existing settings remain compatible.

## Preserved behavior

3.0.11 keeps the 3.0.10 Season 2 GearData dataset, richer Builds metadata, Blizzard-like ordered Rune presentation, Mind Freeze detector/glow/sound, Live Mentor, Review, DK Tools, Setup Wizard, Alert Studio, localization, and Loadout Pilot responsibility boundary.

Gear Mentor remains advisory and read-only. It does not equip items, spend Crests, buy items, apply enchants/gems, change talents, or perform protected actions.

## Version

- DK Mentor: **3.0.11**
- World of Warcraft Retail / Midnight: **12.1.0**
- Interface: **120100**
- SavedVariables schema: **31**
- Setup Wizard schema: **301**
