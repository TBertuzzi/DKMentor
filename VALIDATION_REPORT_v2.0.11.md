# DK Mentor 2.0.11 — Validation Report

Date: 2026-08-26
Target: World of Warcraft Retail / Midnight 12.1
Interface: 120100

## Result

**PASS (offline validation).** Live WoW acceptance is still required for the manual language override scenario.

## Automated checks

- `python3 scripts/validate.py` — PASS
- `texluac -p` — PASS for all runtime Lua files
- `texlua tests/codex_smoke.lua` — PASS
- `texlua tests/mentor_engine_smoke.lua` — PASS
- `texlua tests/localization_smoke.lua` — PASS

## Localization regression coverage

The new localization smoke test simulates a ptBR WoW client where static addon modules are created before SavedVariables are available. It verifies that:

- English override converts cached/static addon text back to English.
- World / Delve / Dungeon / Mythic+ / Raid / PvP context labels use the selected addon language.
- Survival/Coach static text follows the selected addon language.
- Guide and Codex static text follows the selected addon language.
- Blood / Frost / Unholy addon specialization labels can be resolved independently from the WoW client locale.
- Switching the same static tables back to ptBR restores Portuguese labels.

WoW-provided spell/item/aura names intentionally remain in the game client's locale.

## Runtime SHA-256

- `DKMentor.toc`: `5c917d0ba5ac41721666ec1d56a286dbd9596c9a5549a0a4cdbd879566968c69`
- `Localization.lua`: `b293df9addcdf4e120ec69e331fc1b196f4c73e39d9e6c9ccfc0f01b3648857b`
- `Data.lua`: `b8afbd911889c17a67763218ca61b62121c10380478ccfdb20a142e59510dcdb`
- `Builds.lua`: `6169c4f5bfcfe18d4d7d852c0b6d9f0696edd9f90638dd1048296272f22cdb8c`
- `Guides.lua`: `ff8055fac97ec866950b9ed5da4af7e8eb76fc6d583a3796220dd1bbbd4a3807`
- `Codex.lua`: `4e490df4281cbd2b6299e7e17b05a26f07517fcadf5f08cbd95f4403aeef4187`
- `Voices.lua`: `c011212d529f3282aee78b87679cfe6c8a57678ea6ac9a937256ae9bf0807633`
- `Core.lua`: `35c68f90791b8300bf1dad800499ef0bdfe2125f08023ed214fd0f1f68da9273`
- `MentorEngine.lua`: `a424b7cbff7615170d3600f029875e7a239553d80c287835d7b6609de156aa40`

## Live acceptance focus

On a ptBR WoW client, select **English** in DK Mentor and `/reload`. Confirm that addon-owned context labels and guidance become English while Blizzard-provided spell names may remain Portuguese. Then switch back to Portuguese and repeat.
