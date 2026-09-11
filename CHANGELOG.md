## 3.3.1 - 2026-09-11 - Guidance and Valeera Hotfix

- Added a dedicated Valeera **Nemesis / Azta'rec** preset: Healer + Corrosive Bilespear + Soul-Cracking Dreamcatcher + Phantasmal Spore Toxin, with Soulthirst Venom documented as an alternative.
- Separated generic **High Tier / Hard Delves** from the boss-specific Nemesis recommendation.
- Refreshed Unholy Preparation with current optional alternatives from the September 10 Wowhead consumables update: Powerful Eversong Diamond, Flask of the Blood Knights, Refulgent Whetstone and Refulgent Weightstone.
- Corrected Unholy PvP presentation for the current contradictory Icy Veins page: Pet/Rider is the practical Recommended profile; Disease/San'layn remains the rot-pressure Alternative; the ambiguity is disclosed in the UI note.
- Re-audited Blood, Frost and Unholy PvE builds, Hero Talents, gear, trinkets, crafting, tier-set guidance and stat priorities; no broader PvE rewrite was required.
- Reviewed Blizzard's recent Grip of the Dead and Magus of the Dead bug fixes; neither requires combat-engine logic changes.
- Kept live target at Patch 12.1.0 / Interface 120100.
- Data review date: 2026-09-11.

## 3.3.0 Test r10 - Build source audit (2026-09-09)

- Re-audited Blood, Frost and Unholy PvE build profiles by context against current Wowhead guidance.
- Removed the generic per-spec tree-marker assignment that caused Delve/Open World comparisons to inherit Raid/Mythic+ markers.
- Added context-specific, derived and Hero-only coverage modes.
- Frost Delves now validates Deathbringer only until an exact current Delve import is embedded.
- Unholy Raid/Open World no longer reuse Mythic+ AoE markers.
- Renamed `Create in WoW` to `Clone in WoW` so the UI accurately describes the current behavior.
- Build data reviewed date: 2026-09-09.

## 3.3.0 - 2026-09-08 - DK Meta Pulse

- Added the r8 stable-ID Talent Tree pass: guide-node matching now uses Blizzard node/entry/spell IDs and Hero subTreeID, including rank-zero choice/subtree selections, fixing false mapped/selected counts caused by runtime identity differences.
- Added r8 **Create in WoW**: a fully aligned current-spec build can be cloned as a new saved Blizzard talent loadout from the complete generated import string. Saved DK Mentor snapshots can also be recreated directly; newly created loadouts are never auto-activated.
- Added the r7 Talent Tree usability pass: centers the first Hero-tree singleton rows on a shared vertical spine and adds Blizzard loadout export plus reusable DK Mentor talent snapshots. Saved snapshots keep the generated Blizzard import string and the guide-reference spell IDs, remain manual/read-only, and can be copied later from the in-addon Saved library.
- Added the r6 live-layout pass for the Visual Talent Tree: taller 540-unit canvas, independent X/Y fitting, extra padding, and a 40/20/40 Class/Hero/Spec width split to prevent node crowding seen in the first in-game test.
- Added a native Blizzard talent-tree preview to Build Mentor. The primary recommendation now renders Class, Hero, and Spec trees from C_Traits/C_ClassTalents, overlays curated guide-defining talent nodes by stable spell ID, explains why those nodes matter, and compares them with the player's active or saved loadout without changing talents.

- Added a first-class Meta Pulse Codex section with reviewed Archon.gg / Warcraft Logs snapshots for Heroic Raid, Mythic+ +7 to +20, and High Keys.
- Added side-by-side Blood/Frost/Unholy observed Hero Talent usage, sample size, build snapshot, popular weapon, and guide-vs-logs alignment.
- Added ALIGNED, ALIGNED / SPLIT, SPLIT SIGNAL, and META DIFFERS states without allowing observed popularity to silently overwrite guide-backed recommendations.
- Added `/dkm meta` / `/dkm metapulse`.
- Added an optional Archon Tooltip provider router with strict aggregate-schema validation and built-in snapshot fallback.
- Added `ArchonTooltip` as an optional dependency so compatible data can be discovered when available without making it required.
- Added a small `DKMentorMetaBridge` registration surface for compatible aggregate-data providers.
- DK Mentor deliberately avoids `ArchonTooltipPrivate` internals and performs no HTTP requests from inside WoW.
- Fixed Valeera Leveling preset persistence in the Core preset validator.

## 3.2.1 - 2026-09-08 - Unholy Gear Data Hotfix
- Updated Unholy Season 2 Best-in-Slot ring targets from the latest Wowhead gear refresh.
- Added Vile Alchemist's Band (Vashnik) and Sickening Signet of Atroxus (Atroxus / Voidscar Arena) as current Unholy Finger targets.
- Updated Unholy Gear Mentor source metadata to 2026-09-08.
- No changes to builds, Hero Talents, stats, trinkets, crafting, tier guidance, PvP, Valeera, Folio, Preparation, or HUD behavior.

## 3.2.0 - 2026-09-06 - Stats, Folio, Gear Targets 2.0 and Valeera Mentor

- Valeera live-data refresh reviewed 2026-09-06: added a dedicated **Leveling** preset after Blizzard restored companion XP from Mislaid Curiosities.
- Leveling uses **Dundun's Favor** plus **Soulthirst Venom** for curiosity/XP routing while preserving the DK-specific role pairing for Blood/Frost/Unholy.
- Added compact Season 2 live-fix notes for the Sep 4 Darkway curiosity spawn repair, restored Valeera XP, Dundun group-looting repair, the higher-rank **Corrosive Bilespear** proc fix, and Frostheart/Phantasmal poison cleanup on Delve exit.
- Updated Valeera data sources to include Blizzard hotfixes while keeping Corrosive Bilespear + Soul-Cracking Dreamcatcher as the general Curio baseline.
- Fixed the fresh-install / **Reset HUDs** starter layout so Resources, Abilities, Mentor Coach and aura bars no longer pile up near the bottom-center; aura bars now use a separated horizontal row.
- Added a new **Valeera — Delve Mentor** Codex section with native WoW icons, spec-aware role pairing, Season 2 Curio/Poison guidance, and presets for Auto / Safe / Balanced / Fast / High Tier.
- Blood defaults to DPS Valeera for normal farming; Frost and Unholy default to Healer Valeera, with defensive/high-tier variants clearly separated as DK Mentor recommendations rather than universal guide rules.
- Added the current Season 2 Curio baseline (Corrosive Bilespear + Soul-Cracking Dreamcatcher), all six selectable Valeera poisons, concise in-game explanations, and `/dkm valeera`.
- Valeera guidance is recommendation-only: it does not change Valeera's live role, Curios, or Poison automatically.
- Added **Open Valeera setup / Abrir configuração da Valeera**, which loads Blizzard's native Delves Companion Configuration panel so the player can change Valeera's role, Curios, and poison manually from the recommendation page.
- Layout hardening pass for the full DK Codex: expanded the main window to 980x760 and widened the content area so native icons and localized labels have room to breathe.
- Fixed a visual-pool regression where Stats & Folio cards/rune rows could remain visible on top of Equipment subviews after navigation.
- Reworked Gear, Preparation, Sources, Trinkets, Crafting, Upgrades, Overview, and stat-summary rows to measure text and grow vertically instead of overlapping neighboring content.
- Increased spacing around metrics, tier-set panels, Folio rows, navigation buttons, and Equipment subtabs for ptBR/English readability.
- Folio UI polish: native rune icons, spell tooltips, compact status badges, overflow-safe rune rows, and cleaner stat-card typography.
- Added native WoW icons across the DK Codex section menu and key submenus (Build contexts/modes, Equipment views, and Stats & Folio context selectors) without bundling artwork.

- Added the new **Stats & Folio** Codex section with live Critical Strike, Haste, Mastery, and Versatility percentages/ratings.
- Added DK-specific stat direction by specialization, detected Hero Talent, and Auto / PvE / PvP planning context.
- Added visible secondary-stat diminishing-return bands and rating thresholds so the player can see when stacking a stat is entering a weaker conversion band.
- Added a read-only **Omnium Folio Mentor** for Blood, Frost, and Unholy, including PvE/PvP recommendations and live MATCH / REVIEW comparison when the WoW trait API exposes the active Folio safely.
- Added **Gear Targets 2.0** Catalyst plans for each DK specialization and smart item-tooltip annotations for tracked gear, crafts, and Season 2 tier pieces.
- Smart target tooltips now show DK specialization relevance, source, and live EQUIPPED / OWNED / MISSING state.
- Added visible **CURRENT / REVIEW PENDING** freshness metadata to Advisor/build/gear guidance so older guide data is not silently presented as freshly verified.
- Added `/dkm advisor` (plus `folio` / `statsfolio` aliases) to open the new Stats & Folio view directly.
- Kept the system recommendation-only: it never changes talents, Omnium Folio runes, gear, Catalyst choices, crafts, gems, enchants, or combat actions.
- Preserved all 3.1.6 portrait, Preparation, SBA-friendly, preset, DK Ready combat-visibility, and Season 2 data fixes.
- Re-reviewed Frost and Unholy guidance on 2026-09-06 after the September 1 tuning: Frost Mythic+ now explicitly drops Frostbane from the recommended competitive direction, while Unholy build direction remains stable.
- Updated Frost Preparation to Potion of Recklessness, Shattering-Blade-only Razorice main-hand logic, Stoneskin Gargoyle for all other dual-wield builds, and Fallen Crusader-only two-handed Ready Check.
- Marked reviewed Frost/Unholy build/stat/PvP guidance CURRENT while preserving the original guide source-update dates.

## 3.1.6 - 2026-09-03 - Preparation, presets, Lich King portrait and Season 2 refresh

- Prepared the complete 3.1 feature set for public release after the 3.1.0-3.1.6 live-test cycle.
- Added Preparation / Ready Check guidance for Runeforges, enchants, sockets/gems, consumables, and specialization-specific readiness.
- Added an optional SBA-friendly Build Mentor view while keeping defensives, interrupts, control, utility, and situational decisions manual.
- Added DKM31 layout preset export/import with backward-compatible portrait position metadata.
- Added the optional movable/scalable animated Lich King commentary portrait with Arthas/Bolvar selection.
- Stabilized portrait position across hide/show, playback, scale changes, character switching, `/reload`, and preset round-trips.
- Fixed locked portrait helper labels, synchronized portrait lifetime to commentary playback, and corrected the Bolvar Lich King model.
- Added a localized Close / Fechar footer button and fixed Layout Presets modal layering/dragging.
- DK Ready / DK Pronto now hides during combat and returns afterward when enabled.
- Compacted the main window while preserving all existing controls.
- Refreshed 2026-09-03 Blood/Frost/Unholy Gear Mentor, Preparation, and DK Codex guidance from current Patch 12.1 Season 2 sources.
- Updated Frost dual-wield gear/crafting/consumable/Runeforge guidance, Unholy trinket target-count/AoE guidance, and Blood Runeforge/preparation guidance.
- Intentionally kept PvE talent trees, Hero Talents, and PvP talent builds unchanged until verified post-September-1-hotfix guide updates are available.

## 3.1.5 - 2026-09-01 - Voice-synced portrait and compact main window

- Fixed the talking portrait remaining animated/visible after a FileDataID voice had already finished; the returned sound handle is now polled with `C_Sound.IsPlaying` and the fallback timer is cleared as soon as playback ends.
- Reduced portrait shutdown polling from 0.25 s to 0.10 s for a tighter visual/audio finish.
- Reduced the main DK Mentor window from 830x760 to 820x720 and compacted the Settings layout while preserving all HUD, Loadout Pilot and Lich King controls.
- Preserved Arthas/Bolvar selection, top-level Layout Presets, Preparation, SBA-friendly guidance and Frost dual-wield Runeforge support.

## 3.1.4 - 2026-09-01 - Portrait and preset UI polish
- Fixed the Layout Presets window so it always opens above the main DK Mentor window and can be dragged independently.
- Re-aligned all portrait controls onto one clean row in Lich King Commentary settings.
- Corrected the Bolvar portrait source to the in-client **The Lich King** NPC (99456), rather than Bolvar without the Helm of Domination.
- Preserved 3.1.3 portrait animation, character selection, preset persistence, Preparation, SBA-friendly guidance and Frost dual-wield Runeforge logic.

## 3.1.3 - 2026-09-01 - Arthas / Bolvar portrait selector
- Added a configurable animated portrait character: Arthas or Bolvar.
- Added `/dkm voice portrait arthas|bolvar` shortcuts.
- Preserved the portrait-character choice in DKM31 layout preset export/import while keeping older 3.1 preset strings compatible.
- Kept commentary audio unchanged; the selector affects the visual speaker only and bundles no Blizzard assets.

## 3.1.1 - 2026-09-01 - Core.lua local-variable crash fix

## 3.1.2
- Animated the optional Lich King commentary portrait while voice playback is active.
- Fixed Preparation enchant cards that could remain on CHECKING when equipped item links were unavailable.
- Made Frost dual-wield Runeforge guidance explicit by Main Hand and Off Hand.

- Moved 3.1 portrait/preset state and several long-lived constants/helpers onto the addon namespace, reducing chunk-level locals from 215 to 185 without changing gameplay behavior.
- Added a validation guard so future builds fail before packaging if `Core.lua` approaches WoW's 200-local chunk limit.
- Preserved the 3.1 Preparation / Ready Check, SBA-friendly Build Mentor, layout presets, and optional Lich King portrait.

## 3.1.0 - 2026-09-01 - Preparation, accessibility and layout presets
- Added a visual Preparation / Ready Check for Runeforge, common enchants, sockets/gems and current Season 2 consumables.
- Added specialization-aware preparation data for Blood, Frost 2H/Dual Wield and Unholy, including current Runeforge direction.
- Added an optional SBA-friendly Build Mentor view for players who rely on Blizzard Single-Button Assistant, while keeping defensives, interrupts, CC, utility and situational decisions explicitly manual.
- Added DKM31 layout preset export/import for DK Mentor HUD positions and supported visual settings, with bounded parsing and combat-safe import restrictions.
- Added an optional movable/scalable Lich King commentary portrait using WoW-native resources when available, with a safe icon fallback and no bundled Blizzard assets.
- Refreshed the Death Knight data review for Retail 12.1.0 / Midnight Season 2 after checking current Blizzard hotfixes, Wowhead PvE/gear/preparation guidance and Icy Veins PvP guidance.
- Added `/dkm prep` and `/dkm preset` shortcuts plus EN/ptBR localization and live-test coverage for the 3.1 systems.

## 3.0.17 - 2026-08-30 - Visual Build Mentor
- Rebuilt the DK Codex **Builds** section into a visual **Build Mentor**.
- Added manual content selection for **Auto / World / Delves / Dungeon / Mythic+ / Raid / PvP** without changing the player's actual specialization or talents.
- Added visual build profile cards with **Hero Talent icons**, recommendation badges, short focus text, key-talent icons, native WoW spell tooltips, and guide source metadata.
- Expanded current Blood, Frost, and Unholy build guidance from the reviewed Patch 12.1 guide direction while keeping Loadout Pilot responsible for automation.
- Added PT-BR localization for the new Build Mentor interface and recommendation text.

## 3.0.16 - 2026-08-30 - Gear Mentor no-truncation pass and visual crafting
- Reworked Gear Mentor guidance rows so descriptions wrap and grow instead of being cut with ellipses.
- Replaced the text-heavy Crafting page with visual crafted-item cards using real item IDs, icons, ownership state and native WoW tooltips.
- Added current Season 2 crafted fallback targets for Blood, Frost and Unholy based on current Wowhead crafting guidance.
- Shortened Codex side-menu labels while keeping the full section name in the content title, eliminating clipped Portuguese labels.
- Kept specialization icons on Current / Blood / Frost / Unholy; Current continues to follow the active specialization icon.
- Filled missing ptBR Gear Mentor strings, including Upgrade Plan and Frost crafting guidance.
- Simplified tier bonus cards to show the active/inactive state without clipping the bonus explanation; full text remains in the tooltip.

## 3.0.15 - 2026-08-30 - Codex specialization icons and navigation polish
- Added specialization icons to the clickable Codex specialization buttons.
- The **Current** specialization button now shows the icon of the actively selected Death Knight spec.
- Polished the left-side Codex navigation so longer labels fit better and the section list feels more balanced.

## 3.0.14 - 2026-08-30 - Gear Mentor crafting tab and Codex navigation refresh
- Added a dedicated **Crafting** tab in Gear Mentor so players can see recommended craftable fallback pieces when key drops still have not appeared.
- Refreshed the **DK Codex** navigation by moving the section selector into a clearer left-side menu, reducing the "click above then click below" confusion.
- Improved text readability in the Codex/Gear Mentor area with stronger contrast and text shadows on the lighter helper texts.
- Kept the existing Gear, Sources, Trinkets and Upgrades views while preserving the Tier Set overview.


## 3.0.12 - 2026-08-30 - Tier Set & Gear Mentor polish

- Fixed Gear Mentor item tooltips that could remain visible after the pointer left an item card by adding explicit ownership cleanup plus a lightweight hover-state fallback.
- Replaced the unclear Overview Setup counter with a Season 2 tier-set progress card.
- Added a visual Baleful Grave-Knight's Crucible section with five class-set slots, live equipped progress, and 2-piece / 4-piece status for Blood, Frost, and Unholy.
- Tier piece cards use real item icons and native WoW item tooltips; equipped tier detection reads the live item-set ID so catalyzed/equipped tier pieces are recognized by slot when item data is available.
- Added the same compact tier-piece strip to the Gear view.
- Increased contrast for Gear Mentor helper text, trinket guidance, upgrade-plan text, item metadata, metric labels, and stat snapshot text.
- Shortened the top helper hint to avoid truncation.
- No SavedVariables schema change and no gear automation.

## 3.0.11 - 2026-08-30 - Visual Gear Mentor

- Rebuilt Gear Mentor around item cards instead of long text reports.
- Added real item icons for Blood/Frost/Unholy headline targets with native WoW item tooltips on mouseover.
- Added visual EQUIPPED / OWNED / TARGET states plus item-quality icon borders.
- Redesigned Overview with compact item level, Runeforge, target progress, and setup-status cards.
- Renamed the Targets view to Gear and Upgrade Plan to Upgrades while preserving the existing saved view keys.
- Reworked Sources and Trinkets into visual item layouts; long target reason/source details now live primarily in the item tooltip.
- Condensed current stat direction and live secondary-stat snapshot into a single compact panel.
- Kept Gear Mentor read-only: no equipping, upgrading, purchasing, enchanting, socketing, or loadout automation.
- Preserved the 3.0.10 Season 2 dataset, ordered Rune HUD, richer Builds, and all previous 3.0 systems.

## 3.0.10 - 2026-08-30 - Gear Mentor & ordered Runes

- Promoted the DK Codex Stats & Gear area into Gear Mentor with Dashboard, Targets, Sources, Trinkets, and Upgrade Plan views.
- Added data-driven Blood/Frost/Unholy Season 2 target guidance with item ownership state, priority, loot source, trinket direction, crafting plan, and Crest priorities.
- Added live Gear Mentor snapshot for equipped item level, Runeforge, common enchant coverage, sockets, headline target progress, weapon direction, and next target.
- Enriched Builds with Hero Talent direction, focus, usage context, and patch review metadata while keeping talent/loadout changes recommendation-only.
- Added `/dkm gearmentor` / `/dkm gearing` direct access while preserving `/dkm gear` as the Loadout Pilot handoff.
- Reworked Rune HUD presentation into a Blizzard-like ordered visual pool: ready Runes stay left, spending appears from the right, and recharge progresses left-to-right.
- Added Gear Mentor and ordered-Rune regression tests plus packaging/validation guards for the new GearData module.
- No SavedVariables schema change and no gameplay automation.

## 3.0.9 - 2026-08-30 - Mind Freeze action-bar glow & interrupt sound

- Preserved the existing Midnight Secret-safe Mind Freeze detection engine and added presentation-only enhancements on top of it.
- Added an optional cyan action-bar glow for Mind Freeze when the existing interrupt engine has a valid target cast and Mind Freeze is available.
- Added support for both direct Mind Freeze action buttons and macros whose current spell resolves to Mind Freeze.
- Kept the glow Secret-safe by passing protected `notInterruptible` values directly into `SetAlphaFromBoolean` rather than evaluating them in Lua.
- Added a configurable interrupt sound using a single Blizzard-installed `RAID_WARNING` sound; no audio files are bundled and the sound defaults to OFF.
- Interrupt sound/pulse notification is emitted once per new interrupt window instead of on repeated target-cast refreshes.
- Added Settings -> Interrupt options..., Alert Studio action-glow control, and `/dkm interrupt glow|sound|options` commands.
- Action glow defaults to ON; both glow and sound can be disabled independently without changing the Mind Freeze HUD.
- No SavedVariables schema changes and no automatic casting/targeting.

## 3.0.8 - 2026-08-30 - Spec-aware rotation coverage & font-safe Review

- Fixed Action Bar coverage requiring spells that do not belong to the active specialization/loadout.
- Assisted Combat rotation coverage now filters the native spell list against the currently known spellbook/talent state before counting missing buttons.
- Added an explicit Midnight 12.1 guard that keeps Soul Reaper (343294) Unholy-only, so Frost/Blood are never asked to place it on their bars.
- Kept active spell overrides compatible with coverage checks.
- Replaced the Review subtitle arrow glyphs with font-safe ASCII separators to prevent square/missing-glyph boxes on WoW fonts.
- Added regression guards for spec-aware coverage and unsupported decorative UI glyphs.
- No SavedVariables schema or combat-coaching behavior changes.

## 3.0.7 - 2026-08-30 - Modal window navigation hotfix

- Fixed Alert Studio and Review stacking directly on top of Mentor Intelligence.
- Child windows now temporarily hide their caller and restore it automatically on close/Escape.
- Added nested modal return flow for Mentor Intelligence -> Studio -> Review and Setup/Studio transitions.
- Added deterministic top-level frame levels to Studio and Review.
- No combat logic or SavedVariables schema changes.

## 3.0.6 - 2026-08-30 - Pinned Blizzard next action

- Added an optional fixed first Live Mentor card sourced from Blizzard Assisted Combat via `C_AssistedCombat.GetNextCastSpell(false)`.
- Kept cards 2-3 available for DK Mentor defensives, interrupts, utility, resources, procs, and spec context.
- Added Next action controls to Mentor Intelligence, Alert Studio, and `/dkm mentor nextaction on|off`.
- Prevented duplicate spells between the Blizzard next-action card and DK Mentor cards.
- No automatic casting or targeting.

## 3.0.5 - 2026-08-30 - Live Mentor visual hotfix

- Restored the dark DK Mentor card theme after the 3.0.4 compact layout accidentally reset card backdrops to opaque white.
- Reworked Compact to be genuinely smaller: 96px frame height, 102x64 cards, 24px icons, tighter gaps and lighter borders.
- Tightened Medium and Large presets while keeping all coaching content intact.
- Reduced header padding, close-button footprint, movement hint space and secondary text emphasis.
- Kept dynamic width and all 3.0 coaching/Review/DK Tools behavior unchanged.

## 3.0.4 - 2026-08-30 - Compact Live Mentor HUD

- Redesigned the Live Mentor/preview HUD to be substantially smaller and easier to position without removing its useful coaching content.
- Added Compact / Medium / Large Mentor layout presets; Compact is the new default for profiles that have not chosen a layout yet.
- Compact layout tightens the header, icons, cards, padding, and borders while preserving action, spell, and timing text.
- The Mentor frame width now adapts to the number of populated cards instead of always reserving space for three live recommendations.
- Moved readable health/state text onto its own small header line so it no longer competes with the title.
- Shortened the edit hint from Drag to move to Move on the Mentor HUD.
- Added a Coach layout control to Alert Studio; existing Scale and Opacity controls remain available for fine tuning.
- Preserved 3.0.3 Setup return timing, Settings button readability, subtle melee-range hint, Core crash fix, Review/Patterns, and Midnight safeguards.
- SavedVariables schema remains 31; Setup Wizard schema remains 301.

## 3.0.3 - 2026-08-30 - Settings & Preview UX Hotfix

- Shortened and standardized Settings HUD toggle labels so PT-BR/English text remains single-line and readable.
- Reduced Setup alert/tool preview windows from 8 seconds to 4 seconds and added a lightweight visible auto-return notice.
- Shortened Alert Studio selected-alert previews to the same four-second timing.
- Redesigned the melee range helper as a smaller, softer OUT OF RANGE / FORA DE ALCANCE hint with a 0.30s stable-out-of-range delay.
- Added a permanent Setup 3.0 button in Settings to reopen the five-step wizard; `/dkm setup` remains available.
- Preserved all 3.0.2 crash, glyph, flat-button, DK Toolkit, Essential Mentor, Midnight safety, and Review fixes.
- SavedVariables schema remains 31; Setup Wizard schema remains 301.

## 3.0.2 - 2026-08-30 - Core UI & HUD Hotfix

- Fixed the `UpdateResourceHUD` nil crash caused by `NormalizeResourceVisibilityMode` being declared after an earlier caller.
- Removed unsupported Unicode check-mark glyphs that could render as empty squares in WoW fonts.
- Replaced DK Mentor-owned red Blizzard action buttons with a unified dark/cyan flat style across Core, Mentor, Review, Studio, and Setup UI.
- Improved selected-state feedback for language and HUD toggle buttons and widened the language picker.
- Renamed the static Combat Survival list to **DK Toolkit** to clarify that it is a complete reference, not the live Coach.
- Essential Live Mentor is now urgent-only during normal play and hides when no urgent readable call exists; HUD Preview remains populated and is explicitly labeled as a preview.
- Preserved 3.0.1 Setup Wizard UX, Midnight Secret-safe interrupt handling, Review/Patterns, DK Tools, and Loadout Pilot boundaries.
- SavedVariables schema remains 31; Setup Wizard schema remains 301.

## 3.0.1 - 2026-08-30 - Setup Wizard UX Hotfix

- Rebuilt all five Setup Wizard steps for clear selection feedback and readable controls.
- Steps 1/2 now auto-advance on single-choice selection.
- Steps 3/4/5 now use readable 2x2 grids for multi-option actions.
- Long labels are constrained/wrapped inside taller option buttons.
- Removed the ambiguous Keep current settings footer action.
- Alert/DK Tools previews temporarily hide the wizard and return automatically when finished.
- Alert Studio launched from setup returns to the wizard when closed.
- Added HUD lock-state feedback and Lock/Unlock toggle on the final step.
- Bumped setup schema to 301 so existing 3.0.0 users see the corrected wizard once.
- Preserved all 3.0 combat, Review, Tools, localization, and Midnight safety behavior.

## 3.0.0 - 2026-08-30 - Live Mentor, Review & DK Tools

- Added Review 3.0 with Overview, Timeline, Patterns, confidence-aware observations, positive feedback, and the latest 10 meaningful encounters.
- Added Blood Coagulating Blood / Death Strike readable-pool awareness and post-combat average/max pool snapshots without guessing restricted values.
- Updated Unholy coaching for Midnight around Lesser Ghouls, Dark Transformation, Putrefy, Festering Strike, and Scourge Strike; Dread Plague remains conservative under target-aura restrictions.
- Corrected Frost Breath of Sindragosa coaching for the Midnight model: Runic Power capping is no longer suppressed by the obsolete continuous-drain assumption.
- Added DK Tools: a local Death and Decay timer/charge display and a Secret-safe fail-open out-of-melee warning.
- Added Always / Fade out of combat / Combat Only resource HUD visibility modes.
- Added Alert Studio with category previews, scale, opacity, per-category pulse, and optional built-in Blizzard sounds.
- Added a 5-step 3.0 Setup Wizard and new `/dkm review`, `/dkm patterns`, `/dkm studio`, `/dkm setup`, `/dkm tools`, and resource visibility commands.
- Preserved all 2.0.x Midnight safety, click-through HUD, dynamic popup, localization, and Loadout Pilot responsibility-boundary fixes.
- SavedVariables schema is now 31.

## 2.0.11 - 2026-08-26 - Manual language override hotfix

- Fixed content-context labels staying in ptBR when DK Mentor was manually set to English on a ptBR WoW client.
- Context buttons, detected-content labels, the compact DK Status HUD, Survival/Coach headings, build recommendation context labels, and MentorEngine context titles now resolve through runtime localization.
- Added reverse localization plus a post-SavedVariables static-table refresh so Data, Builds, Guides, Codex, and Voices honor the selected DK Mentor language even though those modules load before the manual override is guaranteed to be available.
- Kept context/spec/tip/coach keys canonical where practical and localized Survival/Coach text at render time to prevent stale language values.
- Specialization labels generated by DK Mentor now follow the addon language override; spell/item names supplied by the WoW client remain in the WoW client language by design.
- Added a localization regression smoke test for ptBR-client -> English-addon and English/ptBR round trips.
- No SavedVariables schema change; schema remains 30. No combat logic changed from 2.0.10.

## 2.0.10 - 2026-08-26 - Release Candidate polish

- Added an out-of-combat Test Alerts preview using the real Defensive/Proc/Resource coach cards plus the Mind Freeze HUD.
- Added Reset Mentor settings while preserving the latest Combat Insights report.
- Kept Reset HUD positions as the recovery path for misplaced HUDs.
- Added `/dkm mentor test|reset` and clarified in help that DK Mentor recommends actions but never casts abilities.
- Added a one-time 2.0 upgrade notice describing the Loadout Pilot responsibility split.
- Added non-destructive SavedVariables migration guards for stale/invalid HUD anchors, coordinates, scale, and opacity.
- SavedVariables schema is now 30; valid 1.x/2.0 settings and legacy loadout mapping data are preserved.
- Preserved 2.0.9 Secret-safe Mind Freeze presentation, dynamic Combat Insights popup, click-through HUD behavior, and all Midnight 12.1 safeguards.

## 2.0.9 - 2026-08-26 - Secret-safe Mind Freeze indicator

- Fixed the Mind Freeze interrupt indicator remaining hidden in Midnight restricted combat when `UnitCastingInfo` / `UnitChannelInfo` returned `notInterruptible` as a Secret Value.
- Reworked interrupt presentation to pass the raw `notInterruptible` boolean directly into `Frame:SetAlphaFromBoolean`, matching Midnight's supported pass-through UI model instead of branching on the combat value in Lua.
- `castBarID` is used only as the NeverSecret cast-presence signal; Secret interruptibility is never inspected, compared, negated, formatted, or used for Lua control flow.
- Readable `UNIT_SPELLCAST_INTERRUPTIBLE` / `UNIT_SPELLCAST_NOT_INTERRUPTIBLE` events remain transition fallbacks; the indicator also refreshes on the lightweight 120 ms HUD heartbeat so restricted event payloads cannot suppress it.
- The interrupt frame is click-through during normal gameplay and only becomes mouse-enabled while HUD editing is explicitly unlocked.
- Added `/dkm interrupt status` for safe diagnostics; it reports whether the API state is readable, unavailable, or Secret-driven without exposing the Secret value.
- Preserved the 2.0.8 dynamic Combat Insights popup and all previous 2.0 Midnight safeguards.
- No SavedVariables schema change; schema remains 29.

## 2.0.8 - 2026-08-25 - Dynamic compact Combat Insights popup

- Reworked the post-combat DK Mentor Score popup to size itself from the rendered title and insight text instead of reserving a fixed 500x116 panel.
- Compact one-line reports now use a much smaller footprint, while longer localized text wraps only as needed.
- Width is bounded between 300 and 480 UI pixels and also respects the current UI width.
- Height is calculated from the actual wrapped FontString height, so the panel grows only when the report needs more lines.
- The popup shows at most three insights; any additional insight count is folded into a compact `(+N more)` suffix.
- Changed the score heading from a large font to the normal heading font to reduce visual dominance without losing readability.
- Preserved click-through behavior, the 12-second auto-hide, the persistent full report in Mentor Intelligence, and every 2.0.1-2.0.7 safety fix.
- No SavedVariables schema change; schema remains 29.

## 2.0.7 - 2026-08-25 - HUD edit-mode polish

- Resource arc drag handle is now session-only and visible exclusively while HUD movement is explicitly unlocked.
- HUD movement starts locked after every UI load, preventing stale SavedVariables from leaving edit chrome on screen.
- Locking or entering protected combat immediately hides and disables the handle.
- The full arc HUD remains permanently click-through.

## 2.0.6 - 2026-08-25 - Midnight combat-log hotfix

- Fixed an `ADDON_ACTION_FORBIDDEN` error during addon load caused by the Adaptive Coach registering `COMBAT_LOG_EVENT_UNFILTERED`, which is unavailable to third-party addons in Midnight.
- Removed every runtime dependency on `COMBAT_LOG_EVENT_UNFILTERED` and `CombatLogGetCurrentEventInfo`.
- Defensive pressure now derives from safe player-health deltas instead of combat-log damage events; damage school is intentionally not inferred.
- Mind Freeze scoring now correlates the player `UNIT_SPELLCAST_SUCCEEDED` event with an active interrupt window, while target `UNIT_SPELLCAST_INTERRUPTED` marks the opportunity as handled without requiring CLEU.
- Blood Bone Shield stacks are refreshed through the player-owned aura API and correctly fall back to zero when the aura is absent.
- Unholy target aura guidance remains conservative: restricted combat aura state is never guessed.
- Added validator and smoke-test guards that fail the build if forbidden Midnight combat-log registration is reintroduced.
- No SavedVariables schema change; schema remains 29.

## 2.0.5 - 2026-08-25 - Adaptive DK Coach and Combat Insights

- Upgraded the existing Coach into a live Adaptive DK Coach with Essential, Mentor, and Training intensity modes.
- Added defensive prioritization from readable health/recent-damage state, including magic-pressure awareness and Blood Bone Shield guidance.
- Integrated Mind Freeze and possible Asphyxiate/Blinding Sleet/Death Grip cast stops into the Coach priority system.
- Added readable-state resource/proc coaching for near-cap Runic Power, idle Runes, Blood/Frost/Unholy proc windows, Frost Breath safeguards, and Unholy wound/disease state.
- Added World/Delve elite emphasis and generic boss-cast response awareness without replacing encounter-timer addons.
- Added post-combat Combat Insights with DK Mentor Score, resource/proc/interrupt/defensive components, concise mistakes, and a persistent last-combat panel.
- Added Mentor intelligence settings and `/dkm mentor essential|mentor|training`.
- Preserved all 2.0.1-2.0.4 fixes, Midnight secret-value safeguards, and the Loadout Pilot responsibility boundary.
- SavedVariables schema remains 29.

## 2.0.4 - 2026-08-25 - Mind Freeze interrupt alert reliability

- Fixed the Mind Freeze alert sometimes failing to appear when Midnight delivered `UNIT_SPELLCAST_INTERRUPTIBLE` before the cast API exposed a readable cast state.
- Treats the official target interruptibility events as authoritative until the cast stops, fails, succeeds, becomes non-interruptible, or the target changes.
- Registers interruptibility through target-scoped `RegisterUnitEvent`, matching Blizzard's cast-bar event path, with a safe generic-event fallback.
- Added short deferred refreshes around target/cast transitions so the alert is not lost when combat state or cast information becomes available a frame later.
- Added delayed/channel/empower cast refresh coverage without reading secret combat values.

## 2.0.3 - 2026-08-25 - Resource arcs click-through

- Fixed the large transparent Health / Runic Power arc HUD rectangle intercepting clicks on enemies behind the HUD.
- The 360x300 arc parent is now permanently mouse-transparent during normal gameplay.
- Replaced full-frame dragging with a small edit-only drag handle that appears only while HUDs are unlocked and the player is out of combat.
- Entering combat immediately disables/hides the drag handle even if HUDs were left unlocked, so target selection is never blocked by the resource HUD.
- Preserved arc/rune rendering, saved position, scale/opacity/spacing options, Midnight 12.1 secret-value safeguards, and all 2.0.2 aura HUD fixes.
- No SavedVariables schema change; schema remains 29.

## 2.0.2 - 2026-08-25 - Active-only aura HUD cleanup

- Fixed managed DK Buffs, External Buffs, and Debuffs leaving large empty background/title panels visible while HUDs were unlocked.
- Unlock now enables movement without forcing decorative aura-bar chrome.
- In normal play, locked or unlocked, managed aura HUDs remain icon-only and naturally disappear when Blizzard has no matching active aura to render.
- Preview HUDs remains the explicit positioning mode and still shows the full placeholder/chrome for empty bars.
- Preserved the Midnight 12.1 secret-safe AuraContainer design: no AuraButton visibility probing and no OnShow/OnHide hooks.
- Preserved all 2.0.1 compact status HUD and DK Codex source-row fixes.
- No SavedVariables schema change; schema remains 29.

## 2.0.1 - 2026-08-25 - Compact status HUD and Codex build actions

- Fixed the DK Codex Builds source action row so the localized **Select source URL** button no longer clips its PT-BR label.
- Rebalanced the source URL field and action-button widths without increasing the row footprint.
- Reduced the DK Status HUD height from 42px to 32px and the specialization icon from 32px to 24px.
- Reduced the gap between detected content and **DK READY / DK PRONTO**.
- Removed the large minimum text-column widths and excess trailing space; the widget now sizes closely to its actual localized text while still expanding for longer context names.
- Preserved manual specialization selection, right-click DK Mentor access, dragging, tooltips, Ready Check behavior, and the 2.0 loadout-automation boundary.
- No SavedVariables schema change; schema remains 29.

## 2.0.0

### DK Mentor focus

- Removed DK Mentor's built-in loadout automation engine and Loadouts UI.
- Automatic specialization, talent, equipment, Loot Specialization, and Dungeon Override management now belongs to Loadout Pilot.
- Added optional Loadout Pilot detection/open handoff from Settings, Codex Builds, and `/dkm loadouts`.
- Added DK Codex **Builds** section for recommendation-only, source-linked build guidance.
- Simplified the main UI to Combat / DK Codex / Settings.
- Simplified the DK Status HUD to specialization icon + detected content + DK READY.
- DK Ready now checks DK-specific state only (Runeforge/Ghoul), not mapped talents or equipment.
- Character Check no longer reports talent-loadout or Equipment Set compliance.
- Preserved manual specialization switching from the status icon.
- Preserved legacy 1.x loadout SavedVariables without using them; old auto-switch flags are forced off and schema remains 29.
- Preserved DK Codex, combat HUDs, Resources/Arcs, language support, and Midnight 12.1 secret-aspect safeguards.

# Changelog

## 1.3.4 - 2026-08-25 - Managed loadout code refresh

- `Save code` still stores the pasted talent import string locally for the selected DK profile.
- If that profile is already mapped to its DK Mentor-managed WoW loadout (`DKM World`, `DKM Delve`, `DKM Dungeon`, `DKM Mythic+`, `DKM Raid`, or `DKM PvP`), saving a newer code now refreshes that managed WoW loadout instead of leaving its old talents behind.
- Import strings are validated for serialization version, specialization, and tree hash before DK Mentor asks WoW to change the managed loadout.
- Arbitrary user-named loadouts are never overwritten automatically; only exact DKM-managed names participate in the refresh path.
- If WoW creates a replacement config while importing, DK Mentor rebinds the profile to the replacement, preserves the shared-action-bar setting, restores the previously selected loadout when appropriate, and safely cleans up the older DKM copy.
- If the character is in combat, on the wrong specialization, or WoW rejects the import, the code remains saved locally and the existing WoW loadout is left untouched.
- No SavedVariables schema change; schema remains 29.

## 1.3.3 - 2026-08-25 - DK Codex navigation polish

- Redesigned the DK Codex section navigation into two rows of three buttons instead of squeezing six localized labels into one row.
- Increased section-button width so long PT-BR labels such as `Atributos e equipamento` and `Verificação do personagem` stay inside their buttons.
- Kept the Current/Blood/Frost/Unholy selector on one row and preserved all Codex content, scrolling, and selected-state behavior.
- Shifted the Codex content panel down while preserving its previous bottom edge, avoiding overlap without growing the main window.
- No SavedVariables schema change; all 1.3.2 secret-aspect aura fixes and 1.2.x Loadouts behavior are preserved.

## 1.3.2 - 2026-08-25 - Secret-safe aura-bar hotfix

- Fixed `Button:HookScript(): Cannot assign script handler for 'onshow' (blocked by secret aspects)` on Retail 12.1.
- Removed all DK Mentor `OnShow`/`OnHide` hooks and visibility probes from Blizzard-owned AuraButtons.
- Managed aura bars now follow Midnight's secret-aspect rules: Blizzard alone owns aura-button visibility while DK Mentor keeps its decorative bar chrome hidden during normal locked gameplay.
- With HUDs locked, DK Buffs, External Buffs, and Debuffs render only their active Blizzard-managed icons, so no empty black panel remains when there is nothing to display.
- HUD Preview and unlocked mode still show the frame/title so the bars can be positioned normally.
- Added validation guards that reject AuraButton visibility queries or script hooks in the managed-aura path.
- No SavedVariables schema change; DK Codex, Loadouts 2.x, role-safe specialization switching, and all existing settings are preserved.

## 1.3.1 - 2026-08-25 - Empty aura bar auto-hide

- DK Buffs, External Buffs, and Debuffs no longer leave an empty framed panel on screen when they have no active aura buttons.
- Retail 12.1 AuraContainer remains active while the empty chrome is hidden, so new buffs/debuffs can appear immediately without polling protected aura data.
- Empty aura bars remain visible while HUD Preview is enabled or HUDs are unlocked, preserving drag/position configuration.
- Legacy/fallback aura rendering keeps its existing active-only behavior.
- No SavedVariables schema change; all 1.3.0 Codex and 1.2.x Loadouts behavior is preserved.

## 1.3.0 - 2026-08-25 - DK Codex

- Rebuilt the old beginner Guide into a full **DK Codex** while preserving `/dkm guide` and adding `/dkm codex`.
- Added browse-only Current/Blood/Frost/Unholy selectors that never change the playing specialization.
- Added Overview, Stats & Gear, Rotation, Survival, Utility, and Character Check sections.
- Added Patch 12.1 stat priorities, Hero Talent overviews, Runeforge guidance, gems, enchants, consumables, cheat sheets, beginner openers, cooldown guidance, DK mechanics, survival, interrupt/CC, movement, and group utility guidance.
- Added a live read-only Character Check for profile/talents/gear, Runeforge, ghoul state, common enchant slots, empty sockets, current secondary-stat snapshot, and known/talented utility.
- Kept Runeforge recommendations advisory so valid build/weapon/Hero Talent alternatives do not become false hard errors.
- Kept SavedVariables schema 29; Codex preferences are added through normal defaults with no new database migration.
- Preserved Loadouts 2.x, Dungeon Overrides, Loot Spec, role-safe switching, fast spec retries, compact HUD interaction, aura HUDs, and DK Arcs.

## 1.2.3 - 2026-08-25 - Faster specialization response and HUD shortcut

- Matched the Loadout Pilot specialization request path by preferring `C_SpecializationInfo.SetSpecialization`, with the ClassTalents API kept as a fallback.
- Reduced the duplicate automatic specialization-attempt guard from 4 seconds to 2 seconds.
- Added retry handling for transient specialization-switch failures instead of abandoning the pending target after one rejected attempt.
- The first automatic profile after entering the world is now attempted after about 1 second instead of waiting for the heavier 4-second aura/voice cache refresh.
- Reduced the post-specialization follow-up delay from 1.0 second to 0.5 second so talents, gear, Loot Spec, and HUD state can settle sooner after the spec change is confirmed.
- Added **right-click on the compact Build HUD** to open/close the DK Mentor main window, matching Loadout Pilot behavior.
- Left-click on the specialization icon continues to open the manual Blood/Frost/Unholy specialization picker.

## 1.2.2 - 2026-08-25 - Loadouts 2.0 migration hotfix

- Fixed a login/reload Lua error while upgrading an existing DK Mentor database from schema 28 to 29.
- The 1.2.1 migration accidentally called a nonexistent `CopyTableDeep()` helper while copying Dungeon talent/gear mappings into the new Mythic+ profile.
- The migration now uses DK Mentor's existing `DeepCopy()` helper, so existing Dungeon mappings can seed Mythic+ without aborting `InitializeDatabase`.
- Added regression validation that rejects future builds if the undefined helper returns or if the schema-29 migration stops using the declared copy helper.
- No behavior or UI changes beyond the hotfix; Dungeon Overrides, Loot Spec, unified dungeon identity, role protection, compact HUD, and manual spec switching remain unchanged.

## 1.2.1 - 2026-08-24 - Dungeon Overrides parity

- Fixed Dungeon Overrides talent/equipment/Loot Spec pickers so they always render above the override editor instead of behind it.
- Added a dedicated **Mythic+** content profile, while preserving the separate regular Dungeon profile.
- Existing 1.2.0 Dungeon mappings are copied to the new Mythic+ profile once during upgrade so established setups are not lost.
- Added per-dungeon **Loot Specialization** overrides, including **No override**, **Current specialization**, Blood, Frost, and Unholy. Loot Spec remains independent from the specialization/role used to play the dungeon.
- Added Loot Spec restoration: when a dungeon loot override ends, DK Mentor restores the loot specialization that was active before the override session.
- Unified dungeon-specific overrides around a stable `dungeon:<InstanceID>` identity so the same rule is reused across Normal, Heroic, Mythic 0, and Mythic+.
- Added migration for older Challenge Mode / instance / map dungeon keys and lazy migration when a stable InstanceID becomes known after entering a dungeon.
- Mythic+ is detected while a keystone is slotted, before the timer starts, so the M+ profile can be prepared while WoW still permits changes.
- Dungeon-specific fields left on Inherit now follow the active **Dungeon** or **Mythic+** fallback profile automatically.
- Extended role-safe automatic specialization switching to Dungeon, Mythic+, Raid, and PvP; same-role Frost <-> Unholy changes remain allowed.
- Added role/loot/override details to the compact Build HUD tooltip without changing its one-line presentation or manual specialization selector.
- Added transition refresh handling for role assignment, Loot Spec updates, keystone slot/reset, and battleground-status changes.
- Ported Loadout Pilot's verified equipment retry behavior: a gear swap stays pending until the mapped WoW Equipment Set is actually reported as equipped, and transient out-of-combat failures are retried.

## 1.2.0 - 2026-08-24 - Loadouts 2.0

- Added optional specialization mapping for World, Delve, Dungeon, Raid, and PvP profiles, with **Do not change** as the backward-compatible default.
- Added **Spec AUTO** alongside Talents AUTO and Gear AUTO.
- Added automatic specialization switching orchestration so talents and gear are applied only after the requested specialization becomes active.
- Added Dungeon/Raid role protection that skips automatic Tank <-> DPS specialization changes when they conflict with the player's assigned group role.
- Added dynamic **Dungeon Overrides** discovered from WoW Challenge Mode / Mythic+ data and visited instance IDs rather than a hardcoded seasonal dungeon list.
- Dungeon overrides can independently inherit, keep current, or override specialization, talent loadout, and equipment set.
- Updated DK READY to report specialization readiness and understand Keep-current dungeon overrides.
- Updated the compact Build HUD to show the actual dungeon name when available while preserving manual specialization switching from the spec icon.
- Preserved all existing 1.1.x mappings and settings through schema 28 migration.

## 1.1.10 - Compact Build HUD

- Redesigned the Build HUD into a single compact horizontal row inspired by the LoadoutPilot presentation.
- The specialization name is no longer repeated as text; the specialization icon identifies the active DK spec.
- Removed TALENTS AUTO / GEAR AUTO from the HUD; those states remain available in Settings.
- Preserved content/context, active build, associated gear set, and DK READY status in the one-line HUD.
- Preserved manual specialization switching: click the specialization icon to open the Blood/Frost/Unholy picker.

## 1.1.9 - 2026-08-23

- Fixed the language picker opening behind the main DK Mentor settings window. It now uses `FULLSCREEN_DIALOG`, a high frame level, and explicit mouse interaction so all language buttons are clickable.
- Removed the automatic `ReloadUI` call after choosing a language because Retail can block it as a protected `Reload()` action and raise `ADDON_ACTION_BLOCKED`.
- Language selection is now saved immediately and DK Mentor asks the player to type `/reload` manually to apply the language across the full interface.

## 1.1.8 - 2026-08-23

- Added a **DK Mentor language selector** in Settings.
- Default remains **Automatic (WoW)**: ptBR clients use Portuguese; other currently unsupported client locales fall back to English.
- Added explicit **Português (Brasil)** and **English** overrides saved in `DKMentorDB`.
- Selecting a language reloads the UI immediately outside combat so every window, tooltip, guide label, and HUD text is rebuilt consistently.
- During combat, the preference is saved and DK Mentor asks the player to use `/reload` after combat.
- Added `/dkm language auto|ptbr|en` plus aliases `/dkm lang` and `/dkm idioma`.

## 1.1.7 - 2026-08-23
- Hotfix: restored the DK Arcs Runic Power appearance exactly as intended in 1.1.5.
- Root cause was packaging, not the Runic Power logic: the 1.1.6 ZIP omitted the three right-side arc textures (`DKArcFillRight`, `DKArcBGRight`, `DKArcGlowRight`), causing WoW to render the right StatusBar as a plain rectangle.
- Fixed both release packaging scripts to always include the complete `Media` folder.
- Added regression validation so left/right DK Arc assets cannot be omitted from future packages.
- Kept the 1.1.6 <=30% red Health warning unchanged.

## 1.1.6 - 2026-08-23
- Fixed the DK Arc low-health warning so the Health arc now turns red at **30% HP or lower during combat**.
- The threshold now uses DK Mentor's secret-safe `GetPlayerHealthPercent()` path instead of depending on raw `UnitHealth` / `UnitHealthMax` arithmetic, which can be inaccessible in Midnight combat.
- No visual/layout changes to the 1.1.5 DK Arcs design.

## 1.1.5 - 2026-08-23

- Re-enabled **moving DK Arcs** while keeping the visual HUD completely clean: there is no `Arcos do DK / Mover` header anymore; when HUDs are unlocked or Preview is active, the invisible Arc HUD area can be dragged.
- Added an independent saved position for **DK Arcs**, so switching back to the Classic resource HUD no longer overwrites the Arc placement.
- Added configurable **Arc opening** from 65 to 165 units (shown as a relative percentage) so players can close the arcs toward the character or open them wider without changing overall HUD size.
- Fixed the **Runic Power arc** by replacing runtime texture mirroring with dedicated right-side mirrored textures. Both Health and Runic Power now use their own correctly oriented StatusBar artwork.
- Preserved the six centered Rune indicators and the <=30% Health red warning.

## 1.1.4 - 2026-08-23
- Hotfixed a reload-time Lua error introduced in 1.1.3: the Classic DK Resources constructor accidentally called the DK-Arcs centering helper before that local function existed.
- Restored the Classic resource HUD to its normal saved-position path while keeping DK Arcs permanently auto-centered.
- Added a regression validator that rejects future builds if the Classic constructor calls the later DK-Arcs helper again.
- Low-health red coloring now updates even when numeric resource text is disabled.

## 1.1.3 - 2026-08-23
- Fixed the left DK Arc orientation so the Health arc now curves inward correctly and sits inside its dark track.
- Removed the movable "DK Arcs / Drag" handle; the arc HUD is now auto-centered on the screen/player focus area and controlled only by size and opacity.
- Added low-health feedback: when player health reaches 30% or lower, the Health arc and percentage text turn red.

## 1.1.2 - 2026-08-23

- Rebuilt **DK Arcs** from the ground up using an IceHUD-style architecture: true **vertical texture-driven StatusBars** rather than the previous fake segmented arc.
- Added original `DKArcFill`, `DKArcBG`, and `DKArcGlow` textures created specifically for DK Mentor; no IceHUD art is bundled.
- Fixed the previous invisible-arc problem by removing the broken texture path approach and using dedicated addon media textures.
- **Health** now fills the left curved bar and **Runic Power** fills the right curved bar from bottom to top, matching the familiar IceHUD/Tibia HUD reading pattern.
- Replaced the center Rune bars with six **Blizzard Death Knight rune glyphs** that refill vertically; rune color follows the active DK specialization (Blood red, Frost blue, Unholy green).
- Kept **Classic** as an alternative style, plus scale, opacity, text toggle, Preview HUDs, HUD lock, combat-only visibility, and `/dkm resources style classic|arcs`.
- Health and Runic Power use direct StatusBar value flow so the HUD remains compatible with Midnight secret-value restrictions; numeric text is shown only when the raw values are accessible.
- Added IceHUD attribution/inspiration notes to third-party notices while keeping DK Mentor code and artwork original.

## 1.1.1 - 2026-08-23

- Reworked **DK Arcs** to be much closer to the **IceHUD/Tibia side-HUD feel** requested by the user.
- Removed the large square panel from the arc style and replaced it with a **clean floating layout**.
- Added a **small drag handle** that only appears while HUDs are unlocked or Preview HUDs is enabled.
- Repositioned the UI so **Health stays on the left arc**, **Runic Power on the right arc**, and **Runes sit in the center**.
- Kept the feature fully configurable by the player through the existing **DK Resources** controls.

## 1.1.0 - 2026-08-23

- Added a new **DK Arcs** resource style: an original side-HUD layout inspired by IceHUD readability, with **Health** on the left, **Runic Power** on the right, and **six Rune mini-bars** beside the resource arc.
- Preserved the previous horizontal layout as **Classic**, so players can freely switch between **Classic** and **DK Arcs** without losing the same saved position, scale, opacity, combat-only behavior, or preview support.
- Added a **Style** control to **HUD appearance...** for DK Resources, plus `/dkm resources style classic|arcs`.
- DK Arcs reuses the same resource toggles (**Runes + Runic Power / Runes only / Runic Power only**), **Power text ON/OFF**, **Preview HUDs**, and **Restore DK Resources** workflow.
- Added arc-style visual updates for Health and Runic Power while keeping Rune recharge logic spec-agnostic for Blood, Frost, and Unholy.
- Kept the feature **identity-original**: this is a DK-focused implementation inspired by arc readability, not copied IceHUD code.

## 1.0.21 - 2026-08-23

- Added independent **30%-100% opacity** controls for DK Buffs, External Buffs, Debuffs, Abilities, and DK Resources.
- Expanded the HUD appearance window with dedicated Size, Opacity, and Icons/Mode columns while preserving Preview and combat-lock protections.
- Added **Runic Power text ON/OFF** so the resource bar can be used without labels/numeric text for a cleaner layout.
- Added **Compact / Normal / Wide Rune spacing**; the six Rune segments and Runic Power bar resize together without changing resource logic.
- Added **Restore DK Resources**, which resets only the resource HUD position/scale/opacity/mode/text/spacing while keeping its enabled/disabled state and leaving every other HUD untouched.
- Added a compact DK Resources status summary in Settings and a live status line in the appearance dialog.
- Renamed the Settings entry to **HUD appearance...** and added a global **Restore HUD appearance** action for size/opacity/icon-width defaults without moving HUD positions.
- Preserved the native 12.1 AuraContainer path for DK Buffs, the interaction-only HUD lock, hard Preview override, and secret-safe Runic Power StatusBar behavior.
- Added 1.0.21 validation guards for opacity persistence, resource text/spacing options, resource-only reset, and ptBR localization.

## 1.0.20 - 2026-08-23

- Added a movable **DK Resources** HUD with all six Rune recharge segments and a Runic Power bar for Blood, Frost, and Unholy.
- Added independent resource display modes: **Runes + Runic Power**, **Runes only**, or **Runic Power only**.
- Added independent 70%-160% scaling and saved positioning for the resource HUD, integrated with HUD lock/unlock, Preview, reset, and Combat only / Always visibility.
- Added `/dkm resources on|off`, `/dkm resources runes on|off`, and `/dkm resources power on|off`.
- Kept Rune tracking on the normal secondary-resource path while rendering potentially secret combat Runic Power through Blizzard's native `StatusBar` without branching or recommendations from the hidden value.
- When Runic Power is secret, the visual fill stays available but the numeric `current / max` text is intentionally hidden.
- Preview shows representative Rune recharge and Runic Power states so the HUD can be positioned without entering combat.
- Blocked resource layout/mode changes, HUD Preview changes, and HUD position resets during combat to avoid re-anchoring a widget after it has received a secret primary-resource value.
- Preserved the 1.0.16+ Blizzard `AuraContainer` DK Buffs path and the 1.0.19 interaction-only HUD lock behavior.
- Added 1.0.20 release validation guards for resource APIs, secret-safe Runic Power rendering, combat layout protection, localization, and commands.

## 1.0.19 - 2026-08-23

- Fixed **HUDs: LOCKED** making Blizzard-managed aura bars look like they disappeared in combat. The lock state was incorrectly making the DK Buffs / External Buffs / Debuffs host frame fully transparent.
- HUD locking is now **interaction-only**: it prevents dragging and mouse interception, but it no longer changes bar visibility, label visibility, background, border, AuraContainer state, or combat-only behavior.
- **DK Buffs** keeps the same visible shell and native Blizzard `AuraContainer` whether HUDs are LOCKED or UNLOCKED; only the drag hint/mouse interaction changes.
- Kept the 1.0.16 native proc/buff tracking path, the 1.0.17 configurable sizing/Preview behavior, and the 1.0.18 Lua-scope hotfix unchanged.
- Added a regression guard that rejects a release if managed-aura HUD locking makes the host chrome transparent again.

## 1.0.18 - 2026-08-23

- Fixed the 1.0.17 **DK Buffs** regression caused by Lua local-function declaration order. `HideTrackingSlots` and `ShowManagedAuraPreview` were compiled before `ClearTrackingCooldown` existed in local scope, so both paths attempted to call a nil global.
- Restored the normal Blizzard `AuraContainer` DK Buffs runtime path from 1.0.16 while keeping the 1.0.17 configurable sizing and Preview HUD features.
- Fixed **Preview HUDs** throwing an error when creating DK Buffs / External Buffs / Debuffs placeholders.
- Preview now cleanly hides the native aura container, shows movable placeholder icons, and restores the live native container as soon as Preview is disabled.
- Added a release validation guard that fails packaging if the cooldown-reset helper is ever declared after the managed-aura preview/runtime helpers again.

## 1.0.17 - 2026-08-23

- Fixed **Preview HUDs** being immediately hidden by the out-of-combat heartbeat when **Bars only in combat** was enabled. Preview is now a hard layout override for DK Buffs, External Buffs, Debuffs, and Abilities.
- Added visible preview placeholders for Blizzard-managed `AuraContainer` bars, so empty buff/debuff bars can still be seen, moved, and sized out of combat.
- Added a new **Bar size...** configurator in Settings with independent controls for DK Buffs, External Buffs, Debuffs, and Abilities.
- Each combat bar now supports independent **70%-160% scale** and a configurable **icons-per-row** value. Aura bars default to 5 per row; Abilities defaults to 11.
- AuraContainer flow width is rebuilt safely when the icons-per-row setting changes while preserving upward wrapping.
- Ability and compatibility/fallback aura renderers now respect the same configurable row width.
- Added **Restore default sizes** without changing the user's saved HUD positions.
- **Reset HUD positions** now resets position only; it no longer silently discards the user's custom combat-bar sizes.

## 1.0.16 - 2026-08-23

- Replaced the primary **DK Buffs** renderer on Retail 12.1 with Blizzard's native `AuraContainer` instead of trying to infer active auras from restricted `UnitAura`/Cooldown Viewer state.
- The DK Buffs AuraGroup now uses `candidateFilters.includeSpellIDs`, letting Blizzard securely own presence, stacks, duration, expiration, and combat refreshes while DK Mentor controls only the whitelist and presentation.
- Reworked AuraContainer initialization to the current live order: `SetUnit` -> `AddAuraGroup` -> `SetEnabled`, with `SetEnabled` last.
- The DK whitelist is built from the spec's curated proc list plus spell/link/override IDs resolved from the researched Cooldown Manager profiles, including Frost **Max Buff Tracking**, Taeznak/Luxthos Unholy, and Luxthos/Quick Start Blood.
- Increased the native DK Buffs capacity to 30 active auras with five icons per row and upward wrapping, matching the information density of Blizzard's filtered buff tracking without creating one long line.
- Added live `SetAuraGroupCandidateFilters` refresh when Cooldown Manager data/hotfix overrides become available or the player changes specialization.
- Added Blood Season 2 set tracking for **Blood Debt** and **Relentless Rider's Strength**.
- Added **Icy Talons** to the Unholy important-buff fallback list.
- Restored **Bars only in combat** as the migration/default behavior and bumped the settings schema so existing 1.0.15 installs are repaired automatically.
- Hardened combat-exit visibility with stale-latch healing, world/zone resynchronization, immediate combat-end hiding, and delayed visibility rechecks.
- The older manual aura/mirror/proc renderer remains only as a compatibility fallback if the Retail AuraContainer engine is unavailable.

## 1.0.15 - 2026-08-23

- Rebuilt DK proc/buff tracking around current Midnight 12.1 Cooldown Manager recommendations rather than a mostly static spell list.
- Embedded the public Cooldown Manager ID selections from Wowhead's Frost Max Buff Tracking, Khazak Frost profile, Taeznak/Luxthos Unholy profiles, and Luxthos/Quick Start Blood profiles as read-only metadata.
- Added a safe resolver that consumes Blizzard's already-built Cooldown Viewer provider cache for linked/override spell IDs; DK Mentor does not import, change, or call protected Cooldown Manager layout APIs.
- Fixed a major mirror-state bug: Blizzard item `IsActive()` represents a configured cooldown entry, not an active aura. DK Mentor now requires materialized aura evidence (`auraInstanceID`, `wasSetFromAura`, `cooldownUseAuraDisplayTime`, or accessible cached aura data).
- Expanded Frost tracking for Killing Machine, Rime, Frostbane, Freezing Tempest, Killing Streak, Bonegrinder, Icy Talons, Chosen of Frostbrood, Pillar of Frost, and Breath of Sindragosa.
- Expanded Unholy tracking for Sudden Doom, Lesser Ghoul, Runic Corruption, Forbidden Knowledge, Vampiric Strike, Essence of the Blood Queen, Visceral Strength, and current Midnight Dark Transformation.
- Expanded Blood tracking for Bone Shield, Hemostasis, Crimson Scourge, Boiling Point, Vampiric Strike, Essence of the Blood Queen, Visceral Strength, Dancing Rune Weapon, and Vampiric Blood.
- Expanded important cooldown lists for all three specs, including current Midnight spell IDs and hero-talent cooldowns where applicable.
- Added `COOLDOWN_VIEWER_SPELL_OVERRIDE_UPDATED` handling so hotfix/talent override changes invalidate and rebuild the resolver cache.
- Hardened direct player-aura reads against Midnight secret values.

## 1.0.14 - 2026-08-23

- Fixed combat-only DK buff and ability HUDs remaining visible after combat ended, especially after training-dummy/PvP transitions.
- Added an authoritative combat-event latch based on PLAYER_REGEN_DISABLED / PLAYER_REGEN_ENABLED instead of relying only on unit combat booleans.
- Clears stale proc-only fallback states at combat end, while preserving real buffs that are still active.
- Added a heartbeat fail-safe that hides combat-only bars if a normal UI refresh is delayed.

## 1.0.13 - 2026-08-23

- Rebuilt **DK Buffs** as an active-only proc/buff HUD: inactive abilities no longer remain as dim/static placeholders during normal gameplay.
- Polls Blizzard's Tracked Buffs/Tracked Bars viewer on each DK Buffs refresh instead of depending only on hook/event timing, preventing short or newly-added Midnight procs from being missed.
- Uses Blizzard's materialized `auraSpellID` / `auraInstanceID` frame state first, so linked/override procs shown by the native Cooldown Manager can be mirrored without reading restricted aura identity directly.
- Mirrors active tracked buffs dynamically even when the proc was not previously hard-coded in DK Mentor, improving resilience to talent changes and hotfixes across Blood, Frost, and Unholy.
- Keeps proc-glow and known-aura tracking only as fallbacks when Blizzard's tracked-buff viewer is unavailable or the proc is not configured there.
- Preview mode still shows sample icons solely for HUD positioning; outside Preview, zero active buffs means the DK Buffs frame hides completely.

## 1.0.12 - 2026-08-23

- Reworked DK proc tracking so active procs are always prioritized at the start of the DK Buffs bar instead of being pushed behind inactive placeholders.
- Mirrors active entries from Blizzard's Tracked Buffs Cooldown Viewer when available, using its public frame state rather than restricted aura identities.
- Maps Frost action-button proc glows back to their familiar proc icons for Killing Machine, Rime, and Frostbane.
- Expanded Frost tracking with Frostbane, Icy Talons, Bonegrinder, and Killing Streak, while keeping the existing 5-icons-per-row layout.
- Keeps the implementation visual-only: no automatic ability use, targeting, or protected combat action is performed.

## 1.0.11 - 2026-08-23

- Expanded the DK Buff Bar with transient Blizzard proc-glow tracking, so talent/spec procs that light an action button can appear even when their aura identity is restricted in combat.
- Added Blood tracking for Crimson Scourge and Hemostasis, plus Unholy Runic Corruption tracking.
- Changed the DK Buff Bar to wrap at five icons per row and allow up to three rows, preventing new proc icons from creating an excessively wide bar.
- Added an optional movable **Mind Freeze interrupt alert**: an icon-only HUD appears when the current target is confirmed to be casting or channeling an interruptible spell.
- The interrupt alert never casts Mind Freeze or reacts automatically. It only displays Blizzard-provided cast/interruptibility state and uses secret-value guards when the state is restricted.
- Added `/dkm interrupt on|off` and a Settings toggle for the interrupt alert.

## 1.0.10 - 2026-08-23

- Fixed a Midnight 12.1 PvP crash caused by comparing the secret boolean returned by `UnitIsAFK("player")`.
- Added a central accessible-boolean guard before reading boolean results from Unit APIs.
- Applied the same guard to mounted state, combat state, pet existence/death, vehicle/taxi state, and optional voice triggers to prevent similar secret-value errors.
- When a boolean is secret/inaccessible, DK Mentor now skips the optional check instead of attempting to inspect it.

## 1.0.9 - 2026-08-23

- Removed the legacy runtime profile override completely: content detection is now always automatic.
- Removed **Auto** as a selectable context from the combat/context UI; World, Delve, Dungeon, Raid, and PvP are now shown as read-only detected environments.
- Kept Loadouts configuration independent, with World / Delve / Dungeon / Raid / PvP and no Auto entry.
- Fixed the HUD remaining stuck on PvP after leaving a battleground/arena even when automatic equipment had already returned to the World set.
- Added a lightweight environment heartbeat that refreshes the HUD and automatic talent/equipment mappings when the actual instance type changes.
- Force-migrates any legacy manual `modeOverride` back to automatic without deleting configured loadout or equipment mappings.
- Contains no War Mode button/profile/API logic.

## 1.0.8 - 2026-08-23

- Reverted the experimental War Mode button/profile feature completely after live-client testing exposed protected-action and state-synchronization problems.
- Restored the proven 1.0.3 runtime behavior: World, Delve, Dungeon, Raid, and PvP remain the only automatic content profiles.
- Added a one-time SavedVariables cleanup that removes only experimental War Mode mappings and resets stale War Mode/manual overrides without touching existing World/Delve/Dungeon/Raid/PvP talent or equipment mappings.
- Kept the compact dynamic Build HUD, AddOns-list icon, specialization switcher, DK Ready Check, Runeforge Guard, Ghoul Guard, automatic talent/equipment switching, aura HUDs, and all pre-War-Mode fixes.

## 1.0.3 - 2026-08-23

- Made the specialization icon in the Build HUD interactive.
- Clicking the icon now opens a compact Blood / Frost / Unholy selector.
- Specialization changes are always user-initiated and blocked during combat; DK Mentor never changes specialization automatically.
- Existing automatic talent-loadout and equipment switching continues after the player's selected specialization finishes changing.

## 1.0.2 - 2026-08-23

- Changed the Build HUD to use a safe dynamic height based on the actual rendered lines.
- Removed the unused empty area below the normal five-line HUD state.
- The HUD still grows automatically when localized text or readiness warnings wrap to additional lines.
- Kept conservative minimum and maximum height limits to avoid layout instability.

## 1.0.1 - 2026-08-23

- Added addon icon metadata for the Blizzard AddOns list, using a Death Knight class icon for better visual identity.
- Refined the Build HUD layout to remove the large empty right-side area and keep the information panel more compact and proportional to its content.
- Moved the auto-switch status line into the main text column so the HUD reads more cleanly while preserving the existing information.

## 1.0.0 - 2026-08-22

- Added **DK Ready Check** to the compact Build HUD. It verifies the current context's mapped talent loadout, mapped equipment set, Death Knight Runeforge coverage, and the Unholy ghoul when applicable.
- Added **Runeforge Guard** using the permanent enchant IDs on the player's own equipped weapon item links. Dual-wield characters require a valid Death Knight Runeforge on both equipped weapons.
- Runeforge Guard intentionally validates that a DK Runeforge is present; it does not claim a single rune is universally optimal for every build or encounter.
- Added **Ghoul Guard** for Unholy. It checks the player's own pet state and reports a missing/dead ghoul when Raise Dead is available, while avoiding travel/vehicle false alarms.
- Added `/dkm ready` to print a detailed readiness report to chat.
- Expanded the Build HUD tooltip with talent, equipment, Runeforge, and ghoul readiness details.
- Added live Ready Check refreshes after equipment, inventory, pet, talent, context, and automatic-swap changes.
- Kept the entire 1.0 feature set display/guidance-only: no combat actions are cast, no enemy protected state is read, and no secret-value bypass is attempted.
- Includes the 0.8.3 saved-loadout synchronization fix that keeps Blizzard's native talent selector aligned with automatic switches.
- Prepared synchronized Test, CurseForge, and GitHub packages for extended live-client testing before publication.

## 0.8.3 - 2026-08-22

- Fixed the root cause of the persistent **TALENTS QUEUED / Talentos na fila** state: saved loadout IDs are no longer compared against `C_ClassTalents.GetActiveConfigID()`, which is a different working-config ID.
- DK Mentor now tracks the selected saved loadout with `C_ClassTalents.GetLastSelectedSavedConfigID()` and keeps Blizzard's saved-loadout state synchronized after fallback switches.
- Automatic switching now prefers Blizzard's Retail 12.0.5+ `C_ClassTalents.SwitchToLoadoutByIndex()` flow, which routes the change through the default Talent UI and keeps the loadout dropdown synchronized.
- Retained `C_ClassTalents.LoadConfig()` as a compatibility fallback and now calls `UpdateLastSelectedSavedConfigID()` when that fallback completes.
- Pending talent state is cleared from the saved-loadout selection/config completion events instead of comparing incompatible config IDs.
- Prepared synchronized Test, CurseForge, and GitHub release packages.

## 0.8.2 - 2026-08-22

- Fixed the talent-switch completion flow so **TALENTS QUEUED / Talentos na fila** clears correctly after the new loadout becomes active.
- Added a short verification/retry watch for pending talent swaps, which helps when WoW delays or skips the immediate completion event.
- Refreshed the open Blizzard talent UI after addon-driven loadout changes so the visible loadout selector/combobox stays in sync more reliably.
- Prepared synchronized Test, CurseForge, and GitHub release packages.

## 0.8.1 - 2026-08-22

- Fixed the Settings layout so the combat-bars toggle no longer overflows its button, including the longer ptBR label.
- Raised the main-window footer and tightened the commentary section spacing so the bottom status line no longer appears clipped.
- Removed the **Auto** tab from the Loadouts configuration bar. It now shows only the real environments: World, Delve, Dungeon, Raid, and PvP.
- Separated the **loadout configuration context** from the addon's live combat mode override, so choosing a tab in Loadouts edits that environment without forcing the addon into that mode.
- Automatic talent and gear switching are now enabled by default and migrated on update so DK Mentor immediately uses the environment-specific mappings you configure.
- Prepared synchronized Test, CurseForge, and GitHub release packages.

## 0.8.0 - 2026-08-22

- Added a global **Aura/ability bars: Combat only / Always** visibility option for DK Buffs, External Buffs, Debuffs, and the Ability Bar.
- When Combat only is enabled, the four bars stay hidden out of combat and appear automatically when combat starts; HUD Preview still shows them for positioning.
- Added `/dkm combatbars combat|always` as an optional command-line shortcut.
- Includes the 0.7.2 five-icons-per-row upward wrapping for External Buffs and Debuffs.
- Includes the 0.7.2 Settings button-width fixes for ptBR labels.
- Prepared synchronized Test, CurseForge, and GitHub release packages.

## 0.7.2 - 2026-08-22

- External Buffs and Debuffs now wrap at five icons per row instead of growing into a long horizontal strip.
- Additional aura rows grow upward from the saved HUD position, keeping bars practical above action bars.
- Kept Blizzard AuraContainer/AuraButton ownership for combat-safe aura updates in Retail 12.1.
- Widened and rebalanced Settings controls so Portuguese labels such as HUD preview/reset and talent/gear automation no longer clip or overlap.
- Prepared the addon metadata and documentation for public GitHub and CurseForge packaging.

## 0.7.1 - 2026-08-22

- Rebuilt External Buffs and Debuffs on the official WoW 12.1 AuraContainer/AuraButton system so they remain live while aura data is secret in combat, Mythic+, encounters, and PvP.
- External Buffs now uses the secure `HELPFUL|!PLAYER` engine filter instead of trying to identify third-party casters in addon Lua.
- Player Debuffs now uses the secure `HARMFUL` engine filter and no longer disappears when combat restrictions begin.
- Aura icons, cooldown sweeps, countdowns, and application stacks are rendered by Blizzard-owned AuraButtons without exposing restricted aura identity data to the addon.
- Dynamic aura HUD hosts become visually transparent and click-through while HUDs are locked; unlock/preview mode still shows their positioning chrome.

## 0.7.0 - 2026-08-22

- Added a dynamic **External Buff Bar** for helpful auras currently applied to the player by other players or NPCs.
- Added a dynamic **Debuff Bar** for harmful auras currently affecting the player character.
- Both new aura bars are optional, movable, previewable, localized in English/ptBR, and automatically hide when empty.
- Added native duration sweeps and stack-count display through player aura instance IDs when the WoW client exposes those values.
- Added `/dkm externalbuffs on|off` and `/dkm debuffs on|off`.
- Extended HUD lock, preview, reset-position, and Settings controls to the two new aura bars.
- Kept all aura tracking scoped to the player character; no enemy aura inspection or automated reaction is performed.

## 0.6.4 - 2026-08-22

- Fixed Breath of Sindragosa tracking on the Frost Buff Bar for the current 12.1 spell/aura ID.
- Added canonical-to-current spell alias support for buff aura lookup, proc normalization, cast fallback tracking, and Blizzard Cooldown Viewer mirroring.
- Kept the existing Breath duration-extension fallback when Killing Machine or Rime are consumed.

## 0.6.3 - 2026-08-22

- Fixed the minimap button overlapping the minimap on layouts where Edit Mode makes the minimap larger than the default size.
- Replaced the fixed 80 px minimap orbit with a radius calculated from the minimap's live width and height.
- The button center now sits slightly outside the minimap edge so most of the icon remains outside the map instead of covering map information.
- Added automatic repositioning when Edit Mode changes the minimap size, while preserving the player's saved angle.

## 0.6.2 - 2026-08-22

- Reworked Buff Bar combat tracking so it no longer depends only on direct aura reads or the player's Blizzard Cooldown Viewer layout.
- Added a combat-safe runtime buff state cache driven by player spell-cast events and proc overlay events, with direct aura data and Blizzard mirrors used whenever available.
- Added an independent 120 ms Buff Bar refresh heartbeat that continues in combat even when Lich King commentary is disabled.
- Added fallback durations for core Death Knight self-buffs such as Anti-Magic Shell, Icebound Fortitude, Death's Advance, Lichborne, Vampiric Blood, Dancing Rune Weapon, Pillar of Frost, Breath of Sindragosa, and Dark Transformation.
- Killing Machine, Rime, and Sudden Doom now stay tied to proc-glow show/hide events while aura reads are restricted.
- Preserved readable aura-instance IDs when possible so Blizzard DurationObjects can still drive native cooldown sweeps and stack text during restricted combat.

## 0.6.1 - 2026-08-22

- Fixed the Buff Bar and Ability Availability Bar appearing frozen when combat restrictions become active.
- Ability cooldowns and charge recharges now use Blizzard DurationObjects and native Cooldown widgets so countdown sweeps continue updating in combat without reading restricted timer values in Lua.
- Ability readiness/resource visuals now use secret-safe Region APIs when WoW marks usability values as restricted.
- Buff tracking now mirrors Blizzard Cooldown Viewer active-state signals when direct aura lookup is restricted, with linked/override spell matching for better coverage.
- Added proc overlay and restriction-state refresh handling so proc/buff visuals react while fighting instead of waiting for combat to end.
- Hidden HUD drag instructions while HUDs are locked to keep the combat bars cleaner during normal play.

## 0.6.0 - 2026-08-22

- Reworked the main window around clear primary tabs: **Combat / Loadouts / Guide / Settings**.
- Moved the World/Delve/Dungeon/Raid/PvP profile selector inside **Combat** and **Loadouts** only, so Guide and Settings no longer look content-specific.
- Renamed the Builds page to **Loadouts** because it manages talent loadouts, equipment-set mappings, and source recommendations together.
- Removed the oversized Survival Coach toggle from the combat section header; HUD visibility now lives only in Settings.
- Made Guide explicitly specialization-only and Settings explicitly global.
- Moved global talent/gear auto-switch controls into Settings while keeping per-specialization/content mappings in Loadouts.
- Added a HUD layout workflow with **Lock/Unlock HUDs**, **Preview HUDs**, and **Reset HUD positions**.
- HUDs are locked by default to prevent accidental dragging; preview mode temporarily shows every HUD without changing saved visibility settings.
- Added `/dkm hud lock`, `/dkm hud unlock`, and `/dkm hud preview`.
- Increased main-window spacing and text widths to reduce clipping in Brazilian Portuguese.

## 0.5.1 - 2026-08-22

- Fixed the minimap button artwork alignment by matching Blizzard/LibDBIcon-style texture anchoring and using the minimap's effective scale while dragging.
- Fixed talent auto-switch result handling: `C_ClassTalents.LoadConfig` errors are no longer mistaken for successful switches.
- Added an explicit **Choose loadout...** picker so World/Delve/Dungeon/Raid/PvP can map to any existing WoW talent loadout, just like gear-set mapping.
- Added **Use current loadout** and an optional **Create DKM copy** action in the picker.
- Added loadout-ID repair by saved name when a WoW loadout is deleted/recreated.
- Added an early `PLAYER_ENTERING_BATTLEGROUND` switch attempt so PvP talents are requested during the preparation window, before `PVP_MATCH_ACTIVE`.
- Added pending/queued talent status and event-based confirmation when the active loadout changes.

## 0.5.0 - 2026-08-22

- Rebuilt the main window into **Combat / Builds / Guide / Settings** tabs to eliminate overlapping descriptions and controls on the previous single-page layout.
- Added automatic in-game localization: Brazilian Portuguese for `ptBR`, English for English clients, and English fallback for every unsupported locale.
- Added a beginner **Specialization Guide** for Blood, Frost, and Unholy, including Death Knight resources, survival fundamentals, utility, and content-specific tips.
- Added an optional, movable **Buff Bar** for important Death Knight buffs and procs.
- Added an optional, movable **Ability Availability Bar** for important abilities, cooldown state, charges, and temporary resource unavailability.
- Added Settings toggles and `/dkm buffs on|off`, `/dkm abilities on|off`, `/dkm guide`, and `/dkm settings`.
- Added secret-value guards around cooldown/resource state reads used by the new combat HUDs.
- Kept the v0.4.4 login-safety changes and the v0.4.5 existing-Equipment-Set mapping model.

## 0.4.5 - 2026-08-22

- Reworked gear profiles around **mapping existing WoW Equipment Sets** instead of creating duplicate DK Mentor sets.
- Added **Choose gear set...** with a picker that lists the player's saved Equipment Manager sets and shows mapped/equipped/missing status.
- Added **Use currently equipped set** for quickly mapping a saved set that exactly matches the current gear.
- Added `/dkm gear choose` and `/dkm gear equipped`; `/dkm gear save` now maps an existing equipped set instead of creating a new one.
- The same equipment set can be mapped to multiple content profiles, e.g. `PVE` for World/Delve/Dungeon/Raid and `PVP` for PvP.
- Added binding self-repair by equipment-set name when an older saved set ID no longer resolves, addressing persistent `Gear set missing` states after recreation.
- Gear AUTO continues to use the actual detected content and never swaps equipment during combat.

## 0.4.4 - 2026-08-22

- Hotfix for a possible character-login freeze introduced by the v0.4.2/v0.4.3 voice trigger cache.
- Fixed a feedback loop where `ITEM_DATA_LOAD_RESULT` could rebuild and re-request the complete Hearthstone item list repeatedly.
- Hearthstone item data is now requested at most once per item per session, and completion events only process the item that finished loading.
- Mount and Hearthstone discovery is deferred until after `PLAYER_ENTERING_WORLD` and only runs when voice commentary and situational comments are enabled.
- Talent/equipment auto-switching no longer runs from `PLAYER_LOGIN`; it waits until the character has fully entered the world.
- Debounced UI refreshes to reduce event storms during equipment and talent changes.
- Mount-state polling now sleeps completely while Lich King situational commentary is disabled.

## 0.4.3 - 2026-08-22

- Added per-specialization/content WoW Equipment Set associations for World, Delve, Dungeon, Raid, and PvP.
- Added **Save current gear** to create or update managed sets such as `DKM Frost Delve`, using the currently equipped items.
- Added independent **Gear AUTO: ON/OFF** switching alongside talent-loadout automation.
- Added `/dkm gear save`, `/dkm gear clear`, and `/dkm gear auto on|off`.
- Gear swaps are never attempted during combat; blocked swaps are queued and retried after combat or a later supported context transition.
- Added equipment-set status to the movable Build HUD, including equipped state and missing-item count when available.
- Added handling for `EQUIPMENT_SETS_CHANGED`, `EQUIPMENT_SWAP_FINISHED`, and `PLAYER_EQUIPMENT_CHANGED` so the UI stays synchronized with WoW.
- Clearing a DK Mentor gear binding leaves the player's WoW Equipment Set intact.

## 0.4.2 - 2026-08-22

- Added an explicit **Coach HUD: ON/OFF** setting in the main Survival section; closing the coach now updates the same saved setting.
- Added a movable **Build HUD** showing the Death Knight specialization icon, detected content, active/saved WoW talent loadout, and AUTO/MANUAL state.
- Added `/dkm hud on|off` and a Build Manager toggle for the Build HUD.
- Added **Lich King Voice Mapping** so each supported situation can use Random, Disabled, or a specific installed voice resource selected by preview.
- Added per-situation voice choices for mount, Hearthstone, combat, bosses, death/resurrection, AFK, major DK abilities, control/interrupts, and defensives.
- Improved mount commentary reliability by detecting mount summon spells directly from `UNIT_SPELLCAST_SENT` and retaining mounted-state polling as a fallback.
- Improved Hearthstone commentary by requesting item data, rebuilding spell mappings after `ITEM_DATA_LOAD_RESULT`, and matching loaded localized Hearthstone spell names.
- Added live priority-event status to help verify whether Mounting/Hearthstone was detected and whether the selected voice played.
- Resetting frame positions no longer re-enables HUDs the player intentionally disabled.
- No third-party audio or addon code is bundled.

## 0.4.1 - 2026-08-22

- Fixed Build Manager saving: **Create DKM loadout** now asks WoW to create named loadouts such as `DKM Delve`, `DKM Raid`, `DKM World`, `DKM Dungeon`, and `DKM PvP`, then binds them to the detected content type.
- Added completion handling for `TRAIT_CONFIG_CREATED` / `TRAIT_CONFIG_LIST_UPDATED`.
- Added guaranteed situational Lich King attempts for mounting (with anti-spam cooldown) and Hearthstone cast-start comments.
- Added Hearthstone, Garrison Hearthstone, and Dalaran Hearthstone triggers without bundling game audio.
- Hardened the Survival Coach health reader against Midnight secret values so a restricted health value cannot break the coach during combat.
- The Survival Coach is explicitly shown on combat start when enabled.
- Added `/dkm coach on` and `/dkm coach off`.

## 0.4.0 - 2026-08-22

- Reworked the build panel into a clearer Build Manager.
- Added per-content bindings to actual saved WoW talent loadouts.
- Added optional automatic loadout switching for World, Delve, Dungeon, Raid, and PvP.
- Auto-switching waits until combat ends when a talent change cannot be applied immediately.
- PvE guide references remain Wowhead; Frost and Unholy PvP references now use current Icy Veins 12.1 guides.
- Blood PvP points to current Icy Veins War Mode guidance rather than pretending there is a dedicated Blood arena guide.
- Expanded Lich King commentary with situational login, mount, AFK, pet, control/interrupt, Death Gate, and major offensive triggers.
- Added `/dkm build save|clear|auto on|off` and `/dkm voice situations on|off`.
- No third-party addon code or sound files are bundled.

## [0.3.1] - 2026-08-22

- Made the Survival Coach easy to reposition by dragging the header or any recommendation card.
- Added health-adaptive Survival Coach recommendations using the player health percentage API.
- Added visible health state: Stable, Recover, Danger, and Critical.
- The first recommendation is highlighted when health falls to 70% or lower.
- Added `/dkm coach health on|off`.
- Kept recommendations advisory only; the addon does not automatically cast abilities or claim cooldown availability.

## [0.3.0] - 2026-08-22

- Replaced generic PvE build-focus profiles with contextual references to the current Wowhead Blood, Frost, and Unholy PvE talent guides for patch 12.1.0.
- Added content-aware recommendations for Open World, Delves, Dungeons/Mythic+, and Raid.
- Added visible guide author, guide update date, reviewed patch, and DK Mentor review date.
- Added a selectable source URL field in the build panel.
- Kept talent import strings user-supplied and stored locally instead of redistributing third-party import strings.
- Kept PvP profiles independent from the PvE Wowhead references.
- Preserved all v0.2.0 Lich King Commentary and survival coaching functionality.

All notable changes to DK Mentor are documented here.

## [0.2.0] - 2026-08-22

### Added

- Optional Lich King voice commentary, disabled by default.
- A dedicated `Voices.lua` data module containing only numeric references to voice resources already present in the game client.
- Contextual comments for zone entry, combat starts, combat victories, encounter starts, encounter victories, player deaths, resurrections, and selected defensive casts.
- Low, Normal, and High commentary-frequency presets with randomized event chances and minimum cooldowns.
- A voice preview button and `/dkm voice test` command.
- Independent PvP voice permission through `/dkm voice pvp on|off`.
- Voice status display with the current client locale.
- Shift-right-click on the minimap button to toggle commentary.
- Commentary settings migration in SavedVariables schema 3.

### Changed

- Expanded the main window to include the commentary controls.
- Updated help text, release documentation, packaging scripts, static validation, and mocked API tests for the voice feature.
- Added explicit notices that no Blizzard audio files are bundled or redistributed.

### Safety and behavior

- Commentary pauses during cinematics.
- A new comment is not started while another tracked comment is playing.
- The same voice resource is not selected twice in a row when alternatives exist.
- Unavailable localized resources fail without blocking the addon.
- Commentary remains atmospheric and never casts abilities or replaces combat guidance.

### Validation status

- Lua source parsing and mocked addon loading passed.
- Voice commands, settings, preview playback calls, database defaults, and package structure were exercised in the test harness.
- Live-client validation is still required for each supported locale because legacy game resources may not be installed or available in every client configuration.

## [0.1.0] - 2026-08-22

### Added

- Initial public beta for World of Warcraft Retail 12.1.0.
- Automatic Death Knight specialization detection.
- Automatic context detection for World, Delve, Dungeon, Raid, and PvP.
- Manual context override.
- Blizzard Assisted Combat highlight toggle and action-bar coverage check.
- Contextual survival guidance and compact in-combat coach.
- Blood-specific tanking guidance.
- Original build-focus profiles for Blood, Frost, and Unholy.
- Local storage for player-supplied talent import codes.
- Movable main window, survival coach, and minimap button.
- English interface, documentation, and release metadata.

### Limitations

- The survival coach is contextual and is not a real-time health, cooldown, or encounter-mechanic analyzer.
- No third-party talent import strings are bundled.
- Final visual behavior must still be verified inside the live game client.
- 3.3.0 r9 guide-key diagnostics: per-key OK/MISSING/SWAP/NOT MAPPED states, explicit mapper-failure wording, and precise Create in WoW blocker tooltips.
