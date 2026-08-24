# Changelog

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
