# DK Mentor 3.0.10 — Gear Mentor & Ordered Runes

DK Mentor 3.0.10 expands the 3.0 release candidate beyond combat coaching and post-combat review with a new DK-specific gearing layer inside the DK Codex.

The goal is not to become a generic item database or an in-game simulator. Gear Mentor turns current Death Knight gearing guidance into actionable, specialization-specific objectives while keeping close item decisions in the hands of simulation tools.

## Gear Mentor

The former Stats & Gear Codex section is now **Gear Mentor** with five views:

- **Dashboard** — live equipped item level, Runeforge state, common enchant coverage, empty sockets, headline target progress, current weapon direction, next target, and current stat guidance.
- **Targets** — high-value Season 2 targets for Blood, Frost, or Unholy with priority, slot, source, ownership state, and a short reason.
- **Sources** — a compact farming route that groups the current headline targets by raid/boss source.
- **Trinkets** — specialization-specific active/passive trinket direction and tracked headline trinkets.
- **Upgrade Plan** — current crafting direction, Crest priority, Catalyst/tier reminders, and conservative upgrade advice.

Exact target items can be marked as:

- `EQUIPPED`
- `OWNED`
- `TARGET`

Item names are resolved from the WoW client when possible, allowing localized clients to display Blizzard's localized item names.

Gear Mentor deliberately uses broad priority labels such as `VERY HIGH` and `HIGH`. It does **not** claim that a listed item is an exact percentage upgrade for your character. Close choices should still be simulated because current gear, Hero Talents, trinkets, item level, and secondary-stat distribution can change the result.

## Specialization-aware Season 2 data

The 3.0.10 dataset is separated into `GearData.lua` so gearing guidance can be refreshed on later Blizzard patches/releases without rewriting the Gear Mentor engine.

Current data covers Blood, Frost, and Unholy with specialization-specific:

- weapon direction;
- priority targets;
- trinket plan;
- crafting direction;
- Crest/upgrade plan;
- source metadata and review date.

The dataset is reviewed for Retail 12.1.0 / Midnight Season 2 and records its own patch/review/source freshness metadata.

## Richer Builds

Build recommendations now provide more context instead of only a recommendation name and source.

Where available, the Codex now includes:

- Hero Talent direction;
- build focus;
- when/why to use the profile;
- patch review date;
- existing source metadata.

Builds remain recommendation-only. DK Mentor never creates, imports, selects, or switches talent loadouts; Loadout Pilot remains responsible for loadout automation.

## Blizzard-like Rune ordering

The DK Resources HUD now presents Runes as an ordered visual pool instead of exposing Blizzard's underlying Rune IDs in apparently random positions.

The display now behaves like the native Blizzard Rune frame:

- ready Runes remain grouped on the **left**;
- spending visually removes Runes from the **right**;
- recharging Runes are ordered by progress so they refill visually **left to right**;
- the most recently spent / least-charged Rune remains farthest to the right.

This is presentation only. DK Mentor never changes Rune mechanics, spending, regeneration, or ability behavior.

## Convenience

Added `/dkm gearmentor` (and `/dkm gearing`) to open the Gear Mentor dashboard directly.

The existing `/dkm gear` command remains the Loadout Pilot handoff for equipment/loadout automation, preserving the responsibility split between the two addons.

## Preserved 3.0 systems

This release keeps all previous 3.0 behavior, including:

- Adaptive DK Coach;
- pinned Blizzard Assisted Combat next-action card;
- Midnight-safe Mind Freeze detector;
- optional Mind Freeze action-bar glow and sound;
- Review Overview / Timeline / Patterns;
- Combat Insights and DK Mentor Score;
- DK Tools;
- compact Live Mentor layouts;
- Setup Wizard and Alert Studio;
- modal navigation fixes;
- spec-aware action-bar coverage;
- font-safe UI text;
- Loadout Pilot responsibility boundary.

## Safety model

Gear Mentor is read-only. It does not equip items, spend Crests, buy items, apply gems/enchants, change talents, or perform protected actions.

DK Mentor continues to provide guidance only and never automatically casts abilities.

## Version

- DK Mentor: **3.0.10**
- World of Warcraft Retail / Midnight: **12.1.0**
- Interface: **120100**
- SavedVariables schema: **31**
- Setup Wizard schema: **301**
