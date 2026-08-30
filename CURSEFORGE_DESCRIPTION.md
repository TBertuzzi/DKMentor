# DK Mentor

DK Mentor is a World of Warcraft Retail addon built specifically for **Blood, Frost, and Unholy Death Knights**.

**DK Mentor 3.0 is a Death Knight learning loop: Before Combat → Live Mentor → Review → Patterns → Improvement.**

It does not play the game for you. It keeps the important DK state close to the character, surfaces readable combat opportunities, and helps you understand repeated habits after the fight.

## DK Mentor 3.0

### Live Mentor
- Essential / Mentor / Training guidance levels.
- Defensive Advisor.
- Midnight Secret-safe Mind Freeze alert.
- Optional **Mind Freeze action-bar glow** for direct spell buttons/macros when the existing interrupt engine confirms a valid window.
- Optional single built-in Blizzard interrupt sound; OFF by default and no audio files are bundled.
- DK utility suggestions such as Asphyxiate, Blinding Sleet, and Death Grip when appropriate.
- Resource/proc coaching for readable Runic Power, Runes, and spec states.
- Solo/Delve-aware guidance.

### Review 3.0
- **Overview** with DK Mentor Score, components, positive feedback, and confidence-aware observations.
- **Timeline** of important readable combat moments.
- **Patterns** across the latest **10** meaningful encounters.
- Findings are marked HIGH / MEDIUM / OBSERVATION so context-dependent signals are not treated as absolute mistakes.
- Midnight-hidden information is never penalized.

### Current DK specialization awareness
- **Blood:** Bone Shield plus readable **Coagulating Blood** / Death Strike pool context.
- **Frost:** Killing Machine, Rime, resource flow, and the current Midnight Breath of Sindragosa resource model.
- **Unholy:** Lesser Ghouls, Dark Transformation, Putrefy, Festering Strike, Scourge Strike, Runic Power, and conservative target-aura behavior under Midnight restrictions.

### DK Tools
- Movable **Death and Decay** local duration/charge tracker.
- Secret-safe, fail-open **Out of Melee** warning.

### Alert Studio
- Alert category preview.
- Coach scale and opacity.
- Per-category pulse.
- Optional built-in Blizzard sounds (OFF by default).

### Setup Wizard
A five-step first-run/upgraded-user setup for Coach level, resource visibility, live modules, Review/DK Tools, and HUD positioning. Reopen it at any time from Settings or with `/dkm setup`.

### HUDs
- Six Runes + Runic Power.
- Classic or DK Arcs resource presentation.
- **Always / Fade out of combat / Combat Only** resource visibility.
- DK Buffs, External Buffs, Debuffs, cooldown/availability HUDs.
- Click-through normal gameplay; movement chrome only appears in explicit edit mode.
- Compact DK status widget with spec, context, and DK READY.

### DK Codex
Overview, Builds, Rotation, Survival, Stats & Gear, Utility, and Character Check for all three DK specs. Build information is recommendation-only and never switches talents automatically.

## Loadout Pilot integration

Loadout automation is intentionally not part of DK Mentor. Automatic specialization, talents, equipment, Loot Specialization, and dungeon-specific loadout rules belong to the separate **Loadout Pilot** addon. DK Mentor can open Loadout Pilot when installed, but there is no hard dependency.

## Midnight 12.1 safety

DK Mentor respects protected/Secret combat values. Restricted values fail safely instead of being guessed. The addon does not use forbidden combat-log behavior and never automatically casts abilities or targets units.

## Main commands

- `/dkm` — Open DK Mentor.
- `/dkm review` — Open Review Overview.
- `/dkm review timeline` — Open encounter Timeline.
- `/dkm patterns` — Open recurring Patterns.
- `/dkm studio` — Open Alert Studio.
- `/dkm setup` — Reopen Setup Wizard.
- `/dkm tools` — Show DK Tools state.
- `/dkm tools dnd` — Toggle Death and Decay tracker.
- `/dkm tools melee` — Toggle out-of-melee warning.
- `/dkm resources visibility always|fade|combat` — Resource HUD visibility.
- `/dkm mentor essential|mentor|training` — Coach intensity.
- `/dkm interrupt glow on|off` — Toggle the Mind Freeze action-bar glow.
- `/dkm interrupt sound on|off` — Toggle the built-in interrupt sound.
- `/dkm interrupt options` — Open Alert Studio directly on Interrupt.
- `/dkm interrupt status` — Safe interrupt diagnostics.
- `/dkm loadouts` — Open Loadout Pilot when installed.
- `/dkm help` — Full command list.

## Languages

- English
- Português do Brasil

The addon language can be selected independently of the WoW client for addon-owned text. Spell/item names supplied directly by Blizzard may still use the client language.

## License

MIT License.

DK Mentor is an independent community project and is not affiliated with or endorsed by Blizzard Entertainment, Wowhead, Icy Veins, or other third-party guide/addon projects.

---

## ☕ Support the Project

DK Mentor is free and open source.

If you enjoy the addon and want to support its development:

**Buy me a coffee:** https://buymeacoffee.com/bertuzzi
