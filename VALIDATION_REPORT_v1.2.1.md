# DK Mentor 1.2.1 - Validation report

Validation date: 2026-08-24

## Static validation

- `texluac -p` passed for `Localization.lua`, `Data.lua`, `Builds.lua`, `Guides.lua`, `Voices.lua`, and `Core.lua`.
- `python3 scripts/validate.py` passed for version `1.2.1` / Retail interface `120100`.
- No duplicate `addon:` method definitions were detected in `Core.lua`.
- Localization printf placeholder parity passed for directly paired English / Brazilian Portuguese strings.
- Schema 29 migration preserves existing 1.2.0 mappings and seeds the new Mythic+ defaults from Dungeon values only when an M+ value does not already exist.

## Loadout / Dungeon Overrides regression checks

- Dungeon and Mythic+ are independent default profiles.
- A slotted Mythic Keystone is detected before the challenge timer starts.
- Seasonal Challenge Mode maps are resolved to the same stable dungeon InstanceID used by regular dungeon difficulties whenever the Encounter Journal mapping is available.
- Legacy `challenge:`, `mplus:`, `instance:`, `map:`, and `name:` override identities have migration paths into canonical `dungeon:<InstanceID>` rules.
- One dungeon-specific rule is reused across Normal, Heroic, Mythic 0, and Mythic+ while inherited fields use the active Dungeon/Mythic+ fallback.
- Per-dungeon Loot Specialization supports No override, Current specialization, Blood, Frost, and Unholy.
- Loot Specialization is applied/restored independently from playing-spec role protection.
- Apply ordering is playing specialization -> Loot Specialization -> talents -> equipment, with Loot Spec still allowed when a playing-spec switch is pending or role-blocked.
- Role protection covers Dungeon, Mythic+, Raid, and PvP while same-role Frost <-> Unholy changes remain eligible.
- Talent, Equipment, Playing-spec, and Loot-spec pickers use `FULLSCREEN_DIALOG` / level 1200 above the Dungeon Override editor at level 900.
- Closing the Dungeon Override editor hides its child pickers.
- Gear AUTO keeps a swap pending until the mapped Equipment Set is actually reported as equipped and retries transient out-of-combat failures.
- The compact one-line Build HUD and its manual specialization icon selector remain present.

## Packaging checks to perform after ZIP generation

- CurseForge package has exactly one top-level `DKMentor/` folder.
- CurseForge package contains runtime files, license/notices, and all six DK Arc textures only.
- Test package additionally contains `CHANGELOG.md`.
- GitHub package contains the full source tree and 1.2.1 release/testing/validation documentation.
- `zipfile.testzip()` reports no corrupt entries for all generated ZIPs.

Live WoW client testing is still required before publishing the release.
