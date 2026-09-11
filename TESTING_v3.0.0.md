# DK Mentor 3.0.0 — Live test checklist

This is a major feature release. Offline validation cannot reproduce every Midnight Secret Value/event transition, so a real WoW client test is required before public release.

## 1. Startup / migration

- Install over an existing 2.0.11 SavedVariables profile.
- `/reload` with no Lua errors, taint errors, or `ADDON_ACTION_FORBIDDEN`.
- Confirm existing HUD positions remain reasonable.
- Confirm HUDs start locked.
- Confirm the 3.0 notice appears once.
- Confirm the Setup Wizard appears once for an upgraded profile and can be reopened with `/dkm setup`.

## 2. Localization

- ptBR WoW client + DK Mentor English: context labels remain World / Delve / Dungeon / Mythic+ / Raid / PvP.
- Switch DK Mentor to Português + `/reload`: addon-owned labels return to PT-BR.
- Spell/item names supplied directly by WoW may remain in client locale; this is expected.

## 3. Existing HUD regressions

- Resource arcs do not block clicking enemies behind them.
- `Arraste para mover` / movement handles only appear when HUD movement is explicitly unlocked.
- Entering combat hides/disables movement chrome.
- Empty DK Buffs / External Buffs / Debuffs frames are invisible outside Preview.
- Post-combat popup remains compact/dynamic and click-through.

## 4. Mind Freeze

- Target a normal interruptible cast: Mind Freeze indicator appears.
- Non-interruptible cast: indicator is hidden/transparent.
- Channel: indicator follows the active channel.
- Change target mid-cast: alert follows only the current target.
- `/dkm interrupt status` remains safe and useful.

## 5. Review 3.0

Complete several combats of at least 5 seconds.

- `/dkm review` opens Overview.
- Overview shows score/components, **What went well**, and confidence-aware observations.
- Timeline contains plausible relative timestamps and readable events only.
- Patterns aggregates recurring findings across encounters.
- Previous/Next moves through history.
- History retains the newest 10 encounters.
- `/dkm review clear` clears history only after intentionally running the command.

## 6. Blood

- Bone Shield low-stack transitions are still tracked without secret errors.
- When Coagulating Blood is readable, live coach shows `DS pool: N%`.
- Use Death Strike with a readable pool and confirm Timeline records the snapshot.
- Review shows average/max readable Death Strike pool.
- If the pool is restricted/unavailable, Review clearly says unavailable/restricted and does not invent a value.

## 7. Frost

- Killing Machine / Rime coaching still works when readable.
- Runic Power near-cap warning can still occur while Breath of Sindragosa is active; old RP-drain suppression must not return.
- No secret-value/taint errors during Breath/Pillar burst windows.

## 8. Unholy

- Lesser Ghoul stack coaching is visible when the player aura stack is readable.
- At zero stacks, coach can recommend Festering Strike / BUILD GHOULS.
- With stacks, coach can recommend Scourge Strike / SUMMON GHOUL.
- During Dark Transformation, Putrefy can be surfaced when known/ready.
- Restricted Dread Plague/target aura information must never generate a guessed score penalty.

## 9. Death and Decay tracker

- `/dkm tools dnd` toggles it.
- Cast Death and Decay: local timer begins around 10 seconds.
- Readable charges display when available.
- Timer disappears when inactive, except Preview/edit use.
- Tracker is click-through in normal play.
- Unlock HUDs out of combat and confirm it becomes movable.

## 10. Out-of-melee warning

- `/dkm tools melee` toggles it.
- In combat with an attackable target definitely outside the tested melee range, warning appears.
- Move into range: warning disappears.
- No warning is shown for nil/secret/restricted range results.
- No warning with no attackable target.

## 11. Resource visibility

Test `/dkm resources visibility always`, `fade`, and `combat`.

- Always: resource HUD remains at configured opacity out of combat.
- Fade: reduced opacity out of combat; full configured opacity in combat.
- Combat: resource HUD hides out of combat.
- Classic/Arcs style and rune layout remain unaffected.

## 12. Alert Studio

- `/dkm studio` opens out of combat.
- Cycle Defensive / Interrupt / Utility / Resource / Proc.
- Scale/opacity change coach presentation.
- Pulse can be toggled per category.
- Sound is OFF by default; when enabled it uses only built-in Blizzard sound kits.
- Preview shows one selected alert and returns to live state after several seconds.

## 13. Setup Wizard

- `/dkm setup` restarts at step 1.
- Coach mode changes apply.
- Resource visibility changes apply.
- Live module toggles apply.
- Review/popup/DnD/melee toggles apply.
- Final preview/position actions work out of combat.
- Finish stores setup completion and closes the wizard.

## 14. Responsibility boundary

- DK Mentor never auto-casts an ability.
- DK Mentor never targets a unit automatically.
- DK Mentor never changes talents/spec/equipment/Loot Spec automatically.
- `/dkm loadouts` remains a handoff to Loadout Pilot when installed.
