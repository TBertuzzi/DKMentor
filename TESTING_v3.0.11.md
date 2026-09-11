# DK Mentor 3.0.11 — Visual Gear Mentor Live Test Checklist

Offline validation cannot reproduce WoW item-cache behavior, localized item tooltips, UI scale, or live inventory state. Test this build in Retail 12.1.0 before publishing.

## 1. Upgrade / startup

- Install the 3.0.11 Test package over 3.0.10.
- `/reload`.
- Confirm no Lua errors on login.
- Confirm existing HUD positions/settings remain intact.

## 2. DK Codex -> Gear Mentor

Open `DK Codex -> Gear Mentor` or `/dkm gearmentor`.

### Overview

- Four compact cards appear for Item Level, Runeforge, Targets, and Setup.
- Five headline recommended items appear as visual cards for the selected spec.
- Item icons load; uncached items may briefly use the question-mark icon and should refresh when Blizzard item data arrives.
- EQUIPPED / OWNED / TARGET states match the character.
- Item-quality border colors appear after item data is available.
- The compact stat-direction panel is readable and does not overlap the item grid.

### Item tooltip

- Hover every visible item card.
- The normal WoW item tooltip appears with the item's stats/effects.
- DK Mentor adds Priority, Slot, Source, and the short recommendation reason below the native tooltip.
- Moving the mouse away closes the tooltip normally.

### Gear

- The Gear tab shows the spec's tracked headline items in a two-column grid.
- Blood, Frost, and Unholy show their own targets.
- Long item names do not overlap the status/source row.

### Sources

- Items are grouped under their current raid/boss source.
- Each grouped item remains hoverable and shows the native tooltip.
- Groups do not overlap at normal UI scale.

### Trinkets

- The tracked headline trinkets appear first as item cards.
- Short trinket guidance is visible below without becoming a large text wall.

### Upgrades

- Crafting and Crest/upgrade guidance appears in two compact columns.
- No text overlaps or clips at the user's normal UI scale.

## 3. Regression checks

- Gear Mentor remains read-only; no item is equipped or modified by clicking/hovering cards.
- Builds remain recommendation-only.
- Ordered Rune HUD still spends visually from the right and refills left-to-right.
- Mind Freeze HUD/glow/sound still behaves normally.
- Live Mentor, Review, DK Tools and Alert Studio still open normally.
- PT-BR and English labels fit the visual Gear Mentor controls.

## Acceptance

Publish 3.0.11 only after item icons/tooltips refresh correctly in the live client and the two-column layouts remain readable at the normal UI scale.
