# DK Mentor 3.0.0 — Live Mentor, Review & DK Tools

DK Mentor 3.0 expands the addon from a live combat coach into a complete Death Knight learning loop:

**Before Combat → Live Mentor → Review → Patterns → Improvement**

The 3.0 design remains intentionally Death Knight-specific. Loadout automation stays in Loadout Pilot and DK Mentor never casts abilities, changes targets, or performs protected combat actions.

## Review 3.0

A new persistent review system stores the latest **10 meaningful encounters** and separates post-combat learning into three views:

- **Overview** — score, readable components, what went well, confidence-aware observations, and Blood Death Strike pool context when available.
- **Timeline** — a chronological list of important readable events such as resource pressure, low Bone Shield, proc expiry/consumption, defensive windows, Death Strike use, interrupts, and utility opportunities.
- **Patterns** — recurring observations across recent encounters, ordered by frequency/severity rather than raw DPS.

Review findings carry a confidence level:

- **HIGH** — based on directly readable state.
- **MEDIUM** — useful signal that can depend on group/context.
- **OBSERVATION** — coaching information that is not automatically a mistake.

Midnight-hidden data is not penalized.

## Positive feedback

Review is no longer only a list of mistakes. It can surface measurable strengths such as efficient resources, clean proc handling, complete detected interrupt coverage, and responding to every detected danger window.

## Blood: Death Strike pool awareness

Blood can now read **Coagulating Blood** when the player-owned aura is accessible and use its stack/application value as the supported recent-damage pool signal for Death Strike.

The live Coach can display the readable pool, and Review records average/max readable pool at Death Strike casts. If the value is unavailable or restricted, DK Mentor explicitly reports that limitation and invents no estimate.

## Midnight Unholy update

Unholy coaching has been modernized around the current Midnight gameplay model:

- **Lesser Ghoul** stack awareness.
- **Festering Strike** as a readable Lesser Ghoul builder.
- **Scourge Strike** as a Lesser Ghoul conversion/summon decision.
- **Dark Transformation** + **Putrefy** awareness.
- Current Dread Plague spell data is included for reference, but Dread Plague is not made a scoring dependency when target-aura information is restricted.

Legacy Festering Wound IDs remain available for compatibility/reference, but the live 3.0 coach no longer treats old target-bound wound logic as Unholy's core Midnight decision model.

## Frost: current Breath model

Frost no longer suppresses Runic Power near-cap coaching merely because Breath of Sindragosa is active.

Midnight Breath is no longer modeled as the old continuous Runic Power drain. The Codex/Guide now emphasizes the current proc-extension loop around Killing Machine and Rime rather than teaching the obsolete RP-fuel behavior.

## DK Tools

### Death and Decay tracker

A small movable Death and Decay tracker starts a local 10-second ground-effect timer when the player's successful cast is observed and displays readable charges when the API exposes them.

It intentionally avoids a cooldown swipe implementation that could increase taint risk under current 12.x restrictions.

### Out-of-melee warning

A lightweight warning can appear when a spec-appropriate melee ability reports the current target as definitely out of range.

The check is Secret-safe and fail-open: a nil/restricted/secret result hides the warning rather than guessing.

## Resource HUD visibility

The DK Resources HUD now has three visibility modes:

- **Always**
- **Fade out of combat**
- **Combat Only**

Fade mode preserves full opacity in combat and uses a low configurable out-of-combat alpha.

Existing Classic/Arcs resource styles, rune spacing, scale, opacity, and click-through behavior are preserved.

## Alert Studio

The new Alert Studio lets players tune presentation without changing combat logic:

- alert category selection;
- coach scale;
- coach opacity;
- per-category pulse toggle;
- per-category optional Blizzard built-in sound;
- live out-of-combat preview.

Sounds are **OFF by default**. Pulse defaults to defensive/interrupt alerts only.

## Setup Wizard

A one-time 3.0 Setup Wizard guides users through:

1. Coach level — Essential / Mentor / Training.
2. Resource HUD visibility — Always / Fade / Combat Only.
3. Live Mentor modules — Defensive / Utility / Resources / Procs.
4. Review and DK Tools — Review / post-combat popup / DnD tracker / melee warning.
5. Position and preview — test alerts/tools, unlock HUDs, or open Alert Studio.

The wizard can be reopened with `/dkm setup`.

## New commands

- `/dkm review`
- `/dkm review timeline`
- `/dkm review patterns`
- `/dkm review clear`
- `/dkm patterns`
- `/dkm studio`
- `/dkm setup`
- `/dkm tools`
- `/dkm tools dnd`
- `/dkm tools melee`
- `/dkm tools preview`
- `/dkm resources visibility always|fade|combat`

Existing 2.0 commands remain supported.

## Preserved 2.0 safeguards

3.0 keeps the stabilized 2.0 behavior:

- Midnight Secret-safe Mind Freeze presentation.
- No `COMBAT_LOG_EVENT_UNFILTERED` / `CombatLogGetCurrentEventInfo` dependency.
- Resource arc parent remains click-through.
- HUD drag chrome appears only in explicit edit sessions and remains hidden in combat.
- Empty aura containers remain hidden outside Preview.
- Dynamic compact post-combat popup.
- English / Brazilian Portuguese manual language override.
- Loadout Pilot responsibility boundary.

## SavedVariables

Schema is now **31** for the resource visibility migration. Existing valid positions/settings and legacy inert rollback data remain preserved.

## Compatibility

- World of Warcraft Retail
- Midnight 12.1.0
- Interface: `120100`
