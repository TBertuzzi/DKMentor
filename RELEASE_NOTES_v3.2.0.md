# DK Mentor 3.2.0 — Stats, Folio, Gear Targets 2.0 & Valeera Mentor

DK Mentor 3.2.0 expands the addon as a Death Knight-specific planning and gameplay companion for World of Warcraft Retail 12.1 / Midnight Season 2. The release keeps all guidance recommendation-only while adding new in-game tools for stats, Omnium Folio, gear targeting, Delves, and current Season 2 data.

## New — Valeera Delve Mentor

- Added a first-class **Valeera** section to the DK Codex plus the `/dkm valeera` shortcut.
- Added specialization-aware recommendations for **Blood, Frost, and Unholy**, covering Valeera role, Combat Curio, Utility Curio, and Poison.
- Added six presets: **Auto, Safe, Balanced, Fast, High Tier, and Leveling**.
- Added native WoW icons and native tooltips for Curios and Poisons.
- Added an out-of-combat **Open Valeera setup** button that opens Blizzard's own Delves Companion Configuration window for manual changes.
- Kept the current general Curio baseline centered on **Corrosive Bilespear + Soul-Cracking Dreamcatcher**.
- Added a dedicated **Leveling** preset after Blizzard restored Valeera experience from Mislaid Curiosities. The preset highlights **Dundun's Favor** for curiosity/XP routing and **Soulthirst Venom** for movement and sustain.
- Added a compact Season 2 live-fix panel covering the restored Valeera XP route, Dundun group-loot repair, higher-rank Corrosive Bilespear proc fix, Darkway curiosity spawn repair, and Delve-exit poison cleanup.
- DK Mentor never changes Valeera's role, Curios, or Poison automatically.

## New — Stats & Folio Advisor

- Added a dedicated **Stats & Folio** Codex section for Blood, Frost, and Unholy.
- Shows live **Critical Strike, Haste, Mastery, and Versatility** percentages plus raw ratings when readable.
- Shows current secondary-stat diminishing-return bands and rating thresholds.
- Adds specialization/Hero Talent stat direction with **Auto / PvE / PvP** planning modes.
- Blood distinguishes **Deathbringer** and **San'layn** stat direction when the active Hero Talent can be detected.
- Added `/dkm advisor`, `/dkm folio`, and `/dkm statsfolio` shortcuts.

## New — Omnium Folio Mentor

- Added five-row Omnium Folio recommendations for each DK specialization in PvE and PvP contexts.
- Compares recommendations with the live Folio only when WoW exposes the selection safely.
- Displays **MATCH, REVIEW, FIXED ROW, or NOT DETECTED** conservatively.
- DK Mentor never purchases, commits, or changes Folio runes.

## Gear Targets 2.0

- Added specialization-specific **Catalyst plans** for Blood, Frost, and Unholy.
- Added smart DK Mentor annotations to supported item tooltips for tracked gear targets, crafted targets, and Season 2 tier pieces.
- Tooltips can show **EQUIPPED / OWNED / MISSING** state plus which DK specializations target the item.
- Preserved the visual Gear Mentor flow for targets, sources, trinkets, crafting, upgrades, and tier-set progress.

## Season 2 guidance refresh

- Guidance review finalized on **September 6, 2026** against current Season 2 references and Blizzard hotfixes.
- **Frost:** post-September-1 guidance is current. Mythic+ now emphasizes **Smothering Offense** and no longer presents **Frostbane** as a recommended competitive option.
- **Frost Preparation:** **Potion of Recklessness** is the recommended potion; Light's Potential remains an alternative.
- **Frost Runeforge:** Shattering Blade uses **Razorice Main Hand + Fallen Crusader Off Hand**; other dual-wield builds use **Stoneskin Gargoyle Main Hand + Fallen Crusader Off Hand**; two-handed setups use **Fallen Crusader**.
- **Unholy:** post-hotfix build direction was re-reviewed and remains stable.
- **Blood:** current Season 2 build, preparation, and gear direction remains current.
- Build, gear, preparation, advisor, and Valeera datasets expose source/review freshness instead of silently guessing after tuning changes.

## UI and layout improvements

- Added native WoW icons across DK Codex sections, Build contexts, Equipment views, and Stats & Folio selectors.
- Expanded and hardened the Codex layout so long English/ptBR text and native icons have more room.
- Fixed visual-pool leakage where Stats & Folio elements could remain visible after navigating to Gear Mentor views.
- Reworked long cards and rows to grow with their text instead of overlapping neighboring content.
- Fixed fresh-install and **Reset HUDs** positioning so Resources, Abilities, Mentor Coach, and aura bars start in separate bands instead of stacking near the bottom-center.
- Resetting HUD positions preserves which HUDs are enabled or disabled.

## Preserved from 3.1.6

- Preparation / Ready Check.
- SBA-friendly Build Mentor.
- DKM31 layout preset export/import.
- Optional animated Lich King commentary portrait with Arthas/Bolvar selection.
- DK Ready / DK Pronto combat hiding.
- Loadout automation remains delegated to **Loadout Pilot**.

## Compatibility and safety

- World of Warcraft Retail interface: **120100**.
- DK Mentor remains recommendation-focused and does not cast abilities, change talent loadouts, equip gear, spend currencies, catalyze items, craft items, alter Folio runes, or automatically configure Valeera.
- No third-party addon code or talent import strings are redistributed.
- No Blizzard audio, model, or texture assets are bundled; optional commentary references resources already installed by the WoW client.

## Support

If DK Mentor is useful to you and you would like to support development:

https://buymeacoffee.com/bertuzzi
