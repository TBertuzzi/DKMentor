# DK Mentor

DK Mentor is a World of Warcraft Retail addon built specifically for **Blood, Frost, and Unholy Death Knights**.

It combines Blizzard's native Assisted Combat highlighting with survival guidance, contextual specialization/talent/gear profiles with per-dungeon overrides, compact movable HUDs, a DK Ready Check with Runeforge/Ghoul guards, player aura tracking, a beginner guide, and optional immersive Lich King commentary.

## Features

- Automatic Death Knight specialization detection.
- World, Delve, Dungeon, Mythic+, Raid, and PvP context detection.
- Blizzard Assisted Combat offensive highlight.
- Survival Coach with contextual defensive/recovery priorities.
- Existing WoW talent loadout mapping per specialization + content.
- Existing WoW Equipment Set mapping per specialization + content.
- Optional specialization mapping for World, Delve, Dungeon, Mythic+, Raid, and PvP, including **Do not change**.
- Independent **Spec AUTO**, **Talents AUTO**, and **Gear AUTO** switching when WoW allows it.
- A slotted Mythic Keystone is detected before the timer starts so the M+ profile can be prepared while WoW still permits changes.
- Loot Spec supports No override, Current specialization, Blood, Frost, or Unholy and restores the previous Loot Spec when the dungeon override ends.
- Dynamic **Dungeon Overrides** shared across Normal, Heroic, Mythic 0, and Mythic+, discovered from WoW runtime/Challenge Mode data instead of a hardcoded seasonal list.
- Per-dungeon overrides can independently control playing specialization, **Loot Specialization**, talents, and gear; inherited fields follow the active Dungeon or Mythic+ default.
- Dungeon/Mythic+/Raid/PvP role protection skips automatic Tank <-> DPS playing-spec changes that conflict with the assigned group role; Loot Spec remains independent.
- Gear AUTO verifies the mapped Equipment Set is actually equipped and retries transient out-of-combat transition failures instead of clearing pending state too early.
- Compact one-line Build HUD with specialization icon, context/dungeon, active loadout, gear, and DK READY; click the icon for manual Blood/Frost/Unholy switching.
- DK Ready Check for specialization readiness, mapped talents, mapped equipment, Death Knight Runeforge coverage, and the Unholy ghoul when applicable.
- Runeforge Guard validates a DK Runeforge on each equipped weapon without claiming one rune is always optimal.
- Ghoul Guard warns Unholy Death Knights about a missing/dead permanent pet.
- DK Buff Bar for important class buffs/procs.
- External Buff Bar for positive effects applied to you by other players/NPCs.
- Player Debuff Bar for negative effects affecting your character.
- Aura bars default to five icons per row, can be widened/narrowed independently, and grow upward when they wrap.
- Ability Availability Bar for cooldowns, charges, and temporary availability.
- DK Resources HUD with six Rune recharge segments plus Runic Power, with Runes-only / Runic-Power-only modes.
- Optional combat-only visibility for DK Buffs, External Buffs, Debuffs, Abilities, and DK Resources.
- Independent 70%-160% combat-HUD scaling, 30%-100% opacity, configurable icons per row, and resource display modes.
- DK Resources appearance controls for Runic Power text, Compact/Normal/Wide Rune spacing, and resource-only reset.
- Movable HUDs with lock/unlock, Preview override, and position reset.
- Beginner Guide tab for Blood, Frost, and Unholy.
- English and Brazilian Portuguese UI with automatic WoW-client detection or a manual language override.
- Optional Lich King commentary using sound resources already installed by WoW; no Blizzard audio files are bundled.

## Combat and Midnight 12.1

DK Mentor respects WoW's protected and secret combat-value restrictions. It never casts abilities or attempts to bypass protected information. Dynamic aura HUDs use Blizzard's Retail AuraContainer/AuraButton system so the client remains responsible for combat-time aura updates. Rune recharge uses the DK secondary-resource API. Runic Power can be secret in combat, so its value is passed directly to Blizzard's native StatusBar renderer without combat-time threshold logic or recommendations based on the hidden number.

## Build sources

PvE and PvP recommendation panels link to attributed public guide sources. DK Mentor does not bundle third-party talent strings or copy guide prose. Players may store their own import strings locally.

## Commands

Open the addon with `/dkm`, use `/dkm ready` for the readiness report, and `/dkm help` for the complete command list.

## License

MIT License.

DK Mentor is an independent community project and is not affiliated with or endorsed by Blizzard Entertainment, Wowhead, or Icy Veins.
