# DK Mentor 3.3.0 r10 - Build Source Audit

Reviewed: 2026-09-09
Patch: 12.1.0 / Midnight Season 2

## Why this audit exists

r9 reused one specialization-wide `treeKeyTalents` set across every non-PvP context. That was too coarse: a valid Wowhead Delve/Open World loadout could be compared against Raid/Mythic+ markers and appear wrong. r10 removes that model.

The visual tree now distinguishes between:

- `context-markers`: nodes explicitly confirmed for that current guide context;
- `derived-markers`: nodes derived from the nearest current guide context, clearly labeled as derived;
- `hero-only`: only the current Hero Talent direction is validated when an exact full guide import is not embedded.

A marker check is not presented as a full third-party build import.

## Source matrix

### Blood
Primary: Wowhead - Best Blood Death Knight Talent Tree Builds - Midnight, Mandl, updated 2026-08-20.

- Raid: San'layn remains the throughput-oriented primary DK Mentor profile; Deathbringer remains the easier/predictable alternative. Raid validation now uses Raid-specific markers rather than Mythic+ markers.
- Mythic+: both Deathbringer and San'layn remain exposed. DK Mentor keeps Deathbringer as the lower-friction default; current Wowhead text explicitly discusses its plug-and-play/defensive benefits and also the stricter Dancing Rune Weapon management of the alternative. Mythic+ markers include Umbilicus Eternus, Blood Draw and Relish in Blood.
- Delves: kept as the low-friction solo direction. The current guide describes the Delve tree as the Mythic+ shell with group-only elements removed. Delve markers are therefore a smaller solo-safe set rather than a copy of Raid/M+.
- Dungeon: explicitly labeled as derived from Mythic+ rather than pretending Wowhead publishes a separate normal-dungeon best build.
- Open World: explicitly labeled as derived from the current solo/Delve direction.

### Frost
Primary: Wowhead - Best Frost Death Knight Talent Tree Builds - Midnight, khazakdk, updated 2026-09-05.

- Raid: Deathbringer remains the current primary direction. Current confirmed markers: Frostreaper, Smothering Offense, Frostscythe and Glacial Advance. Northwinds remains the documented encounter-specific Frostreaper swap.
- Mythic+: Wowhead explicitly says Frost builds the same as Raid. Smothering Offense carries AoE and Frostbane is no longer the competitive recommendation. Uses the same confirmed marker family.
- Delves: Deathbringer remains the current recommendation because Reaper's Mark provides a frequent cooldown for sturdier enemies. Wowhead exposes a separate Delve row, so r10 no longer reuses the Raid/M+ marker set. Until an exact current Delve import is embedded and verified, validation is Hero-only.
- Dungeon: explicitly derived from Mythic+.
- Open World: conservative Hero-only Deathbringer direction; no claim that a full Wowhead Open World import is embedded.

### Unholy
Primary: Wowhead - Best Unholy Death Knight Talent Tree Builds - Midnight, Taeznak, updated 2026-09-05.

- Raid / Single Target: Rider of the Apocalypse remains the primary DK Mentor direction. Until the exact current Wowhead Single Target import is embedded, validation is Hero-only rather than reusing an AoE marker set.
- Mythic+: Wowhead currently documents two viable families, Rider and San'layn. Rider remains DK Mentor's simpler sustained-AoE default; San'layn remains the disease/Blightfall alternative. Rider markers now focus on Epidemic and Magus of the Dead; San'layn markers on Epidemic and Blightfall.
- Delves: Wowhead says the builds are identical to the Mythic+ families and generally recommends the simpler sustained-AoE option. Delves now uses those same context-specific families rather than a spec-wide generic set.
- Dungeon: explicitly derived from Mythic+.
- Open World: Rider direction retained; validation is Hero-only until the exact current Open World import is embedded.

### PvP
PvP profiles remain based on the current Patch 12.1 Icy Veins PvP references (2026-08-10) and stay intentionally conservative because matchups change talent choices. r10 does not force PvE tree markers onto PvP.

## UI / safety changes

- The tree header now says `source check`, not an implied exact full-build comparison.
- The UI always states its coverage level.
- `Create in WoW` was renamed to `Clone in WoW` because the current implementation clones the compared Blizzard loadout; it does not synthesize a full Wowhead build that we have not embedded exactly.
- The full-guide creation path remains possible later through a verified `guideImportString`, but r10 will not fake it from partial markers.

## Current primary source URLs

- Blood: https://www.wowhead.com/guide/classes/death-knight/blood/talent-builds-pve-tank
- Frost: https://www.wowhead.com/guide/classes/death-knight/frost/talent-builds-pve-dps
- Unholy: https://www.wowhead.com/guide/classes/death-knight/unholy/talent-builds-pve-dps
