<p align="center"><img src="logo/DKMentor_Banner_1200x480.png" alt="DK Mentor banner" width="100%"></p>

# DK Mentor

**DK Mentor** is a World of Warcraft Retail addon built specifically for **Blood, Frost, and Unholy Death Knights**. Version 3.0 expands the project into a complete Death Knight learning loop: **Before Combat → Live Mentor → Review → Patterns → Improvement**.

Loadout automation is no longer part of DK Mentor. Specialization/talent/gear/Loot Specialization automation belongs to the dedicated **Loadout Pilot** addon. DK Mentor can detect Loadout Pilot and open it from Settings or `/dkm loadouts`, but it does not require it.

The in-game UI defaults to Brazilian Portuguese on `ptBR` clients and English on `enUS`/`enGB`, with a manual **Auto / Português / English** override in Settings. After changing the override, use `/reload` to rebuild the UI in the selected addon language. Addon-owned labels, context names, guidance, Codex text, and specialization labels follow that override; spell/item names returned directly by the WoW client intentionally remain in the WoW client language.

## DK Mentor 3.0 focus

- Blood, Frost, and Unholy specialization detection.
- World, Delve, Dungeon, Mythic+, Raid, and PvP **content detection for guidance and HUD labels only**.
- Blizzard Assisted Combat offensive highlighting; DK Mentor never casts abilities.
- Action-bar coverage is filtered to the **active specialization and currently known talent/spellbook state**, so cross-spec/stale Assisted Combat entries are not reported as missing.
- **Adaptive DK Coach** with Essential, Mentor, and Training modes; it prioritizes urgent survival, interrupts, possible control stops, resources, procs, and spec-aware states when the client exposes them.
- **Defensive Advisor** using readable player health and recent health-loss pressure, with Blood-specific Bone Shield/Death Strike/Vampiric Blood handling. It does not inspect the restricted Midnight combat log or guess damage school.
- **Combat Insights + DK Mentor Score** after meaningful combats, with readable resource, proc, interrupt, and critical-health response analysis.
- **Review 3.0** with Overview, Timeline, Patterns, positive feedback, confidence-aware findings, and history for the latest 10 meaningful encounters.
- Blood **Coagulating Blood / Death Strike pool** awareness when the player-owned aura is readable; restricted values are never estimated.
- Current Midnight Unholy coaching around **Lesser Ghouls / Dark Transformation / Putrefy** and updated Frost Breath resource assumptions.
- **DK Tools** with a Death and Decay tracker plus a Secret-safe out-of-melee warning.
- **Alert Studio** and a one-time **3.0 Setup Wizard** for presentation/module configuration; modal parent/child navigation keeps Studio, Review, Setup, and Mentor Intelligence from piling up on top of each other.
- Compact movable **DK Status HUD** showing the specialization icon, detected content, and DK READY state.
- Left-click the status icon to use the normal manual Blood/Frost/Unholy specialization picker; right-click the widget to open or close DK Mentor.
- **DK Ready Check** for class-specific readiness: Death Knight Runeforge coverage and the Unholy ghoul when applicable.
- **DK Codex** with current Blood/Frost/Unholy guidance plus **Gear Mentor**: live gear snapshot, priority targets, loot sources, trinket direction, crafting/Crest plan, enriched builds, Runeforges, gems, enchants, consumables, Hero Talents, rotation, survival, utility, and Character Check.
- Build recommendations are advisory and source-linked. DK Mentor does **not** create, select, import, or switch WoW talent loadouts.
- Optional **Loadout Pilot integration** for players who want automatic specialization, talents, equipment, or Loot Specialization changes.
- DK Buff Bar for important class buffs/procs using Blizzard's Retail 12.1 AuraContainer.
- External Buff Bar for helpful effects applied by other players/NPCs.
- Player Debuff Bar for harmful effects affecting your character.
- Ability Availability Bar for important cooldowns, charges, and temporary availability.
- DK Resources HUD with six Rune indicators plus Runic Power, including the optional **DK Arcs** layout and a Blizzard-like ordered Rune pool (ready left, spend from the right, recharge left-to-right).
- Optional Mind Freeze interrupt alert for a confirmed interruptible target cast/channel, plus an optional **Mind Freeze action-bar glow** for direct spell buttons/macros and a single built-in Blizzard interrupt sound (sound OFF by default). The Adaptive Coach can also surface Mind Freeze and possible DK control stops, but never interrupts automatically.
- Movable, lockable, scalable combat HUDs with Preview mode, opacity controls, icon wrapping, and resource visibility modes for Always / Fade out of combat / Combat Only.
- Release-candidate polish: one-click **Reset HUD positions**, **Reset Mentor settings**, and an out-of-combat **Test alerts** preview for Defensive / Proc / Resource / Interrupt visuals.
- One-time 3.0 Setup Wizard plus release notice; the Loadout Pilot split and recommendation-only safety model remain explicit.
- Optional situational Lich King commentary using sound resources already installed by WoW. No Blizzard audio is bundled.

## Why loadout automation moved out

DK Mentor and Loadout Pilot had started solving the same problem in two places. Version 2.0 separates those responsibilities:

- **DK Mentor:** DK gameplay, class knowledge, HUDs, survival guidance, readiness, resources, buffs/procs, and the DK Codex.
- **Loadout Pilot:** automatic specialization, talents, equipment, Loot Specialization, and content/dungeon loadout rules.

This keeps DK Mentor easier to maintain and lets loadout improvements be implemented once in the addon dedicated to that job.

Existing 1.x/2.x SavedVariables are intentionally preserved for rollback safety. DK Mentor 3.0 moves to schema 31 to migrate the new resource-visibility mode while preserving valid HUD anchors, coordinates, scale/opacity, and legacy inert mapping data. Retired automatic-switch flags remain forced off.

## Retail 12.1 combat restrictions

Modern WoW can protect or hide combat values from addons. DK Mentor does not attempt to bypass those restrictions. It uses Blizzard-owned APIs and UI mechanisms where available, including Assisted Combat, DurationObjects, proc events, and the Retail 12.1 AuraContainer/AuraButton system for dynamic player aura HUDs.

Midnight 12.1 prevents addons from using protected AuraButtons to infer secret aura state. Combat-log events are also unavailable to third-party addons, so DK Mentor never registers `COMBAT_LOG_EVENT_UNFILTERED` and never calls `CombatLogGetCurrentEventInfo`. DK Mentor therefore never attaches `OnShow`/`OnHide` handlers to those buttons and never reads their visibility to decide combat behavior. During normal locked gameplay, DK Mentor hides its decorative aura-bar chrome and lets Blizzard render only the active aura icons.

Runic Power can also become a secret value in combat. DK Mentor passes it to Blizzard's StatusBar rendering path and only performs coaching/score calculations when the number is readable; inaccessible values are ignored rather than compared.

## DK Codex

The **DK Codex** can browse Current, Blood, Frost, or Unholy without changing the specialization you are playing. It contains seven sections:

- Overview
- Builds
- Rotation
- Survival
- Gear Mentor
- Utility
- Character Check

The **Builds** section uses the content DK Mentor currently detects and shows source-linked recommendations for that specialization/content. It is intentionally recommendation-only. If Loadout Pilot is loaded, the Codex can open it directly for players who want automation.

The **Gear Mentor** is item-first and visual: **Overview, Gear, Sources, Trinkets, and Upgrades** use real item icons, compact `EQUIPPED` / `OWNED` / `TARGET` states, item-quality borders, and the native WoW item tooltip on mouseover. The Overview keeps live item level, Runeforge, target progress, **Season 2 tier-set progress (2p/4p)**, and stat direction compact instead of presenting a wall of text. The five Death Knight Season 2 class-set slots are shown visually with live equipped state and tooltip details. Close choices should still be simulated. Gear guidance remains stored in the separate `GearData.lua` dataset so patch/season updates can refresh recommendations without rewriting the UI engine.

Optimization advice is advisory: exact gearing, stat balance, trinkets, and encounter-specific choices should still be simulated when the difference matters.

### Character Check

Character Check is read-only. It reports useful player-owned state such as:

- active specialization;
- DK Runeforge state;
- Unholy ghoul state when relevant;
- common missing permanent enchants;
- empty sockets when item data is available;
- current Crit/Haste/Mastery/Versatility snapshot;
- known/talented DK utility.

It never equips gear, changes talents, sockets gems, applies enchants, or casts abilities.

## DK Ready Check

The compact DK READY result remains deliberately class-specific in 3.0. It checks:

- whether equipped DK weapons have a recognized Death Knight Runeforge when the item data is readable;
- whether the Unholy permanent ghoul is available when that check applies.

It no longer treats a talent loadout, equipment set, Loot Specialization, or content profile as a readiness requirement.

Use `/dkm ready` for the detailed chat report.

## DK Resources HUD

The optional DK Resources HUD keeps the Death Knight resource loop close to the character:

- six Rune recharge indicators presented as an ordered pool: ready Runes on the left, depleted Runes on the right, and recharge visually left-to-right;
- Runic Power bar;
- Runes only / Runic Power only / both;
- Classic bars or optional **DK Arcs** presentation;
- independent scale, opacity, saved position, Preview, and Always / Fade out of combat / Combat Only visibility;
- Runic Power text toggle and Rune spacing controls.

## Aura HUDs

The addon provides three aura concepts:

- **DK Buffs:** important self buffs/procs for the active DK specialization.
- **External Buffs:** positive effects supplied by other players/NPCs.
- **Debuffs:** harmful effects on the player.

They use Blizzard's Retail aura-container system. DK Buffs combines spec-aware candidate data with current Cooldown Manager-related metadata. The bars are display-only and do not automate reactions.

## Installation

1. Download the CurseForge release ZIP or a GitHub release archive.
2. Extract the `DKMentor` folder to `World of Warcraft/_retail_/Interface/AddOns/`.
3. Confirm `World of Warcraft/_retail_/Interface/AddOns/DKMentor/DKMentor.toc` exists.
4. Enable **DK Mentor** on the AddOns screen.
5. Log in on a Death Knight and type `/dkm`.

## Main commands

```text
/dkm
/dkm help
/dkm codex
/dkm builds
/dkm gearmentor
/dkm loadouts
/dkm ready
/dkm coach on|off
/dkm mentor
/dkm mentor essential|mentor|training
/dkm mentor test|reset
/dkm review
/dkm review timeline|patterns|clear
/dkm patterns
/dkm studio
/dkm setup
/dkm tools
/dkm tools dnd|melee|preview
/dkm resources visibility always|fade|combat
/dkm hud on|off
/dkm hud lock|unlock|preview
/dkm buffs on|off
/dkm externalbuffs on|off
/dkm debuffs on|off
/dkm abilities on|off
/dkm resources on|off
/dkm resources runes on|off
/dkm resources power on|off
/dkm resources style classic|arcs
/dkm interrupt on|off
/dkm combatbars combat|always
/dkm settings
/dkm language auto|ptbr|en
/dkm voice
/dkm rotation
/dkm bars
/dkm reset
```

`/dkm build` is an alias for the Codex Builds section. `/dkm loadouts`, `/dkm pilot`, `/dkm gear`, and `/dkm equipment` hand off to Loadout Pilot when it is installed/enabled.

## Lich King commentary

The commentary feature is optional and disabled by default. It references numeric sound resources already present in the player's installed WoW client. DK Mentor does not include, extract, modify, or redistribute Blizzard audio files or dialogue transcripts.

## Development and publishing

- [DK Mentor 3.0.11 live test checklist](TESTING_v3.0.11.md)
- [DK Mentor 3.0.11 release notes](RELEASE_NOTES_v3.0.11.md)
- [DK Mentor 3.0.5 live test checklist](TESTING_v3.0.5.md)
- [DK Mentor 3.0.5 release notes](RELEASE_NOTES_v3.0.5.md)
- [DK Mentor 3.0.4 live test checklist](TESTING_v3.0.4.md)
- [DK Mentor 3.0.4 release notes](RELEASE_NOTES_v3.0.4.md)
- [DK Mentor 3.0.2 live test checklist](TESTING_v3.0.2.md)
- [DK Mentor 3.0.2 release notes](RELEASE_NOTES_v3.0.2.md)
- [DK Mentor 3.0.1 live test checklist](TESTING_v3.0.1.md)
- [DK Mentor 3.0.1 release notes](RELEASE_NOTES_v3.0.1.md)
- [DK Mentor 3.0.0 live test checklist](TESTING_v3.0.0.md)
- [DK Mentor 3.0.0 release notes](RELEASE_NOTES_v3.0.0.md)
- [DK Mentor 2.0.11 localization hotfix checklist](TESTING_v2.0.11.md)
- [DK Mentor 2.0.11 release notes](RELEASE_NOTES_v2.0.11.md)
- [DK Mentor 2.0.10 release-candidate checklist](TESTING_v2.0.10.md)
- [DK Mentor 2.0.10 release notes](RELEASE_NOTES_v2.0.10.md)
- [DK Mentor 2.0.9 live test checklist](TESTING_v2.0.9.md)
- [DK Mentor 2.0.9 release notes](RELEASE_NOTES_v2.0.9.md)
- [DK Mentor 2.0.7 live test checklist](TESTING_v2.0.7.md)
- [DK Mentor 2.0.7 release notes](RELEASE_NOTES_v2.0.7.md)
- [DK Mentor 2.0.5 live test checklist](TESTING_v2.0.5.md)
- [DK Mentor 2.0.5 release notes](RELEASE_NOTES_v2.0.5.md)
- [DK Mentor 2.0.4 live test checklist](TESTING_v2.0.4.md)
- [DK Mentor 2.0.4 release notes](RELEASE_NOTES_v2.0.4.md)
- [DK Mentor 2.0.3 live test checklist](TESTING_v2.0.3.md)
- [DK Mentor 2.0.3 release notes](RELEASE_NOTES_v2.0.3.md)
- [DK Mentor 2.0.2 live test checklist](TESTING_v2.0.2.md)
- [DK Mentor 2.0.2 release notes](RELEASE_NOTES_v2.0.2.md)
- [DK Mentor 2.0.1 live test checklist](TESTING_v2.0.1.md)
- [DK Mentor 2.0.1 release notes](RELEASE_NOTES_v2.0.1.md)
- [Publishing guide](PUBLISHING.md)
- [Policy and sources](POLICY_AND_SOURCES.md)
- [Third-party notices](THIRD_PARTY_NOTICES.md)
- [Security policy](SECURITY.md)
- [Support](SUPPORT.md)

Historical release/test documents remain in the source archive for project history.

## License

DK Mentor source code is released under the [MIT License](LICENSE).

## Credits and trademarks

Developed and maintained by **Thiago Bertuzzi** with AI-assisted implementation and documentation.

World of Warcraft, Warcraft, the Lich King, and Blizzard Entertainment are trademarks or registered trademarks of Blizzard Entertainment, Inc. DK Mentor is an independent community project and is not affiliated with or endorsed by Blizzard Entertainment.
