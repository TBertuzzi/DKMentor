# DK Mentor 3.2.0 — Stats, Folio & Gear Targets 2.0

DK Mentor 3.2 is focused on keeping Death Knight decisions inside the game. The new advisor layer turns current public DK guidance into compact, read-only recommendations for Blood, Frost, and Unholy without turning DK Mentor into a generic Midnight encyclopedia.

## New — DK Stats & Folio Advisor

- Added a dedicated **Stats & Folio** section to the DK Codex.
- Shows the active character's live **Critical Strike, Haste, Mastery, and Versatility** percentages plus raw combat ratings when the client exposes them.
- Shows current **10% / 20% / 30% diminishing-return rating thresholds** for all four secondary stats.
- Adds DK-specific stat direction by specialization, Hero Talent when it can be detected, and PvE/PvP context.
- Adds **Auto / PvE / PvP** planning modes; Auto follows the current detected content.
- Blood distinguishes **Deathbringer** and **San'layn** stat direction.
- Frost and Unholy post-September-1 guidance has now been re-reviewed. Frost Mythic+ explicitly avoids recommending Frostbane; Unholy build direction remains stable.
- Added `/dkm advisor` (plus `statsfolio` / `folio` aliases) for direct access.

## New — Omnium Folio Mentor

- Shows five recommended Omnium Folio rows for each DK specialization and PvE/PvP context.
- Uses current Icy Veins DK Folio recommendations.
- Attempts a **read-only** comparison against the player's live Folio selection through WoW's `C_Traits` tree 1186, with a conservative spell-known fallback that is accepted only when every Folio row resolves unambiguously.
- Displays `MATCH`, `REVIEW`, `FIXED ROW`, or `NOT DETECTED` without ever changing a Folio rune.
- If Midnight does not expose the live selection safely, DK Mentor still shows the recommendation and does not claim the player is configured incorrectly.

## Gear Targets 2.0

- Preserves the existing `EQUIPPED / OWNED / TARGET` Gear Mentor flow.
- Adds a specialization-specific **Catalyst plan** for Blood, Frost, and Unholy using current Season 2 Wowhead guidance.
- Adds DK Mentor information to supported item tooltips for tracked gear targets, crafted targets, and Season 2 tier pieces.
- Tooltip integration shows collection state plus every DK specialization for which the item is a target.
- Gear data now exposes a visible **CURRENT / REVIEW PENDING** freshness line with DK Mentor review date and source update date.

## Native WoW icon navigation

- Added native in-client WoW icons to the **DK Codex section menu** so Overview, Stats & Folio, Equipment, Builds, Rotation, Survival, Utility, and Character Check are easier to identify at a glance.
- Build-context buttons now use compact DK-themed WoW spell icons for Auto, World, Delve, Dungeon, Mythic+, Raid, and PvP without changing their behavior.
- Equipment subviews now use compact native icons for Overview, Gear, Preparation, Crafting, Sources, Trinkets, and Upgrades.
- Standard/SBA-friendly Build Mentor modes and Stats & Folio Auto/PvE/PvP selectors also receive native WoW icons.
- No icon files are bundled: textures are resolved from spells, items, and built-in WoW interface assets already present in the client.

## Build data freshness

- Build cards now show **CURRENT** or **REVIEW PENDING** next to their source metadata.
- Blood build guidance remains current.
- Frost and Unholy PvE/PvP build profiles remain intentionally marked for review while the relevant guide pages are still pre-September-1-hotfix.
- DK Mentor 3.2 does **not** invent replacement talent trees or copy talent strings from other addons.

## Scope kept intentionally small

DK Mentor does not duplicate Midnight Cheat Sheet's expansion-wide item-level, Great Vault, Mythic+, Raid, Prey, Delve, crafting-rank, or editable-wishlist tables. The 3.2 implementation takes only the ideas that improve a DK-specific mentor: live stats, DR awareness, Folio guidance, target status/tooltips, Catalyst direction, and visible data freshness.

## Preserved from 3.1.6

- Preparation / Ready Check and current Season 2 consumable/Runeforge guidance.
- SBA-friendly Build Mentor.
- DKM31 layout presets.
- Arthas/Bolvar optional animated Lich King portrait and its position/lock fixes.
- DK Ready / DK Pronto hiding during combat.
- Loadout automation remains delegated to Loadout Pilot.

## Compatibility and safety

- World of Warcraft Retail interface: **120100**.
- All new 3.2 checks are read-only.
- DK Mentor never changes Folio runes, equips gear, spends currencies, catalyzes items, crafts items, changes talents, or casts abilities.
- No Midnight Cheat Sheet code, talent strings, or assets are included.
- No Blizzard audio/model/texture assets are bundled.

## Data review

- DK Mentor guidance review: **2026-09-06**.
- Current Season 2 gear/Catalyst direction: Wowhead.
- Stat and Omnium Folio direction: current Wowhead / Icy Veins DK pages as identified in the in-game freshness panel.

