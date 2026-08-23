# Changelog

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
