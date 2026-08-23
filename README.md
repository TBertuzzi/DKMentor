<p align="center"><img src="logo/DKMentor_Banner_1200x480.png" alt="DK Mentor banner" width="100%"></p>

# DK Mentor

**DK Mentor** is a World of Warcraft Retail addon for Blood, Frost, and Unholy Death Knights. It combines Blizzard's native Assisted Combat highlighting with survival guidance, content-aware loadout and equipment mapping, compact combat HUDs, a DK Ready Check with Runeforge/Ghoul guards, aura tracking, beginner guidance, and optional Lich King commentary.

The in-game UI automatically uses Brazilian Portuguese on `ptBR` clients and English on `enUS`/`enGB`; unsupported locales fall back to English.

## Highlights

- Blood, Frost, and Unholy specialization detection.
- World, Delve, Dungeon, Raid, and PvP context detection with manual override.
- Blizzard Assisted Combat offensive highlighting; DK Mentor never casts abilities.
- Health-aware Survival Coach for defensive, healing, control, and utility priorities.
- Contextual talent-loadout and Equipment Set mapping with optional automatic switching when WoW permits it.
- Movable Build HUD showing specialization, context, loadout, gear mapping, and automation state.
- **DK Ready Check** in the Build HUD for mapped talents, mapped equipment, Death Knight Runeforge coverage, and the Unholy ghoul when applicable.
- **Runeforge Guard** validates a DK Runeforge on every equipped weapon without pretending one rune is universally best for all builds.
- **Ghoul Guard** warns Unholy Death Knights when their permanent pet is missing/dead, with travel/vehicle suppression.
- DK Buff Bar for important class buffs/procs.
- External Buff Bar for helpful effects applied to you by other players or NPCs.
- Player Debuff Bar for harmful effects currently affecting your own character.
- External buffs and debuffs wrap at **five icons per row** and grow upward instead of becoming a long horizontal strip.
- Ability Availability Bar for important abilities, cooldowns, charges, and temporary unavailability.
- Optional combat-only visibility for DK Buffs, External Buffs, Debuffs, and the Ability Bar; leave it off to keep enabled bars visible outside combat.
- HUD lock/unlock, preview, and reset-position workflow.
- Beginner Guide tab per specialization.
- Optional situational Lich King commentary using sound resources already installed by the WoW client; no Blizzard audio files are bundled.
- Minimap button positioned on the outer edge of the current Edit Mode minimap size.

## Retail 12.1 combat restrictions

Modern WoW can protect or hide some combat values from addons. DK Mentor does not attempt to bypass those restrictions. The addon uses Blizzard-owned APIs and UI mechanisms where available, including Assisted Combat, DurationObjects, proc events, and the Retail 12.1 AuraContainer/AuraButton system for dynamic player aura HUDs.

When the game does not expose a restricted value, DK Mentor avoids pretending that the value is known.

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
/dkm mode auto|world|delve|dungeon|raid|pvp
/dkm coach on|off
/dkm build
/dkm gear
/dkm voice
/dkm buffs on|off
/dkm externalbuffs on|off
/dkm debuffs on|off
/dkm abilities on|off
/dkm combatbars combat|always
/dkm ready
/dkm hud lock|unlock|preview
/dkm reset
```

## Loadouts and equipment

DK Mentor maps **existing** WoW talent loadouts and Equipment Sets to specialization + content profiles. The same PvE set can be reused for World, Delve, Dungeon, and Raid, while another set can be mapped to PvP. Automatic switching is optional and respects normal WoW combat/content restrictions.

No third-party talent import strings are bundled. Build panels link to attributed public guide sources; players can store their own import strings locally in `DKMentorDB`.


## DK Ready Check

The Build HUD includes a compact readiness result and a detailed hover tooltip. It checks only player-owned/configuration state: the content-mapped talent loadout, the mapped Equipment Set, permanent Runeforge enchants on equipped weapons, and the Unholy pet when Raise Dead is available.

Runeforge Guard answers **"is this a Death Knight Runeforge?"**, not **"is this always the mathematically best rune?"**. Rune choice can vary by build and encounter, so the addon avoids presenting a universal optimization claim.

Use `/dkm ready` for a chat report while testing.

## Aura HUDs

The addon provides three separate aura concepts:

- **DK Buffs**: important self buffs/procs for the active Death Knight specialization.
- **External Buffs**: positive effects on the player supplied by other players/NPCs.
- **Debuffs**: negative effects currently affecting the player character.

External Buffs and Debuffs use Blizzard's Retail aura-container system so the game client owns aura assignment and refreshes during restricted combat. They are display-only and do not inspect enemy aura state or automate reactions.

## Lich King commentary

The commentary feature is optional and disabled by default. It references numeric sound resources already present in the player's installed WoW client. DK Mentor does not include, extract, modify, or redistribute Blizzard audio files or dialogue transcripts.

## Publishing and project policy

- [1.0 live test checklist](TESTING_v1.0.9.md)
- [Publishing guide](PUBLISHING.md)
- [Policy and sources](POLICY_AND_SOURCES.md)
- [Third-party notices](THIRD_PARTY_NOTICES.md)
- [Security policy](SECURITY.md)
- [Support](SUPPORT.md)

## License

DK Mentor source code is released under the [MIT License](LICENSE).

## Credits and trademarks

Developed and maintained by **Thiago Bertuzzi** with AI-assisted implementation and documentation.

World of Warcraft, Warcraft, the Lich King, and Blizzard Entertainment are trademarks or registered trademarks of Blizzard Entertainment, Inc. DK Mentor is an independent community project and is not affiliated with or endorsed by Blizzard Entertainment.
