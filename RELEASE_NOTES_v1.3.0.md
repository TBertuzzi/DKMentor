# DK Mentor 1.3.0 - DK Codex

Version 1.3.0 starts a new direction for DK Mentor: in addition to combat HUDs and loadout automation, the addon now includes an in-game Death Knight knowledge base designed to help players understand and improve all three specializations.

## DK Codex

- Replaces the old beginner Guide presentation with a much broader **DK Codex** while keeping `/dkm guide` as a compatible alias.
- Adds `/dkm codex`.
- Browse **Current**, **Blood**, **Frost**, or **Unholy** without changing the specialization you are playing.
- Six focused Codex pages:
  - Overview
  - Stats & Gear
  - Rotation
  - Survival
  - Utility
  - Character Check
- Guidance is marked for **Patch 12.1 / Midnight Season 2** and includes a reminder to simulate the character for exact personal optimization.

## Knowledge added

- Death Knight Rune, Runic Power, and Death Strike fundamentals.
- Current general PvE stat priorities for Blood, Frost, and Unholy, including Blood Hero Talent differences.
- General PvP stat direction for Frost and Unholy.
- Runeforge recommendations and build-sensitive alternatives.
- Gems, enchants, flasks, potions, food, weapon consumables, health potions, and augment-rune guidance.
- Hero Talent overviews for San'layn, Deathbringer, and Rider of the Apocalypse.
- Concise cheat sheets and beginner-friendly openers for all three specs.
- Burst/resource/defensive cooldown handbooks.
- Survival guidance for physical vs. magic damage and Runic Power planning.
- Interrupt, crowd-control, movement, group utility, Death Grip etiquette, Gorefiend's Grasp, Anti-Magic Zone, and Raise Ally guidance.

## Character Check

The Codex now includes a live, read-only character diagnostic that can report:

- active specialization/profile readiness;
- mapped talent loadout;
- mapped Equipment Set;
- DK Runeforge coverage;
- Unholy ghoul state when applicable;
- missing permanent enchants on common Midnight enchantable slots;
- empty sockets when item data is available;
- a live Crit / Haste / Mastery / Versatility snapshot;
- known/talented DK utility spells.

Character Check is intentionally advisory. It does not change gear, talents, enchants, gems, or abilities, and it does not mark a valid alternate Runeforge as wrong when the recommendation depends on build, weapon style, Hero Talents, or encounter shape.

## Compatibility

- SavedVariables schema remains **29**. Existing installs receive the new Codex preferences through normal defaults; there is no new database migration.
- Loadouts 2.0/2.1, Dungeon Overrides, Loot Specialization, role protection, fast specialization retries, DK Arcs, aura HUDs, and compact Build HUD behavior are preserved.
