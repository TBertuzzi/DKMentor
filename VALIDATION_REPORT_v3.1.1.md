# Validation Report — DK Mentor 3.1.1

Date: 2026-09-01

## Startup hotfix

The initial 3.1.0 test package hit WoW/Lua's main-chunk local-variable ceiling:

`Core.lua:7637: main function has more than 200 local variables`

The 3.1 feature additions had raised `Core.lua` to 215 chunk-level locals. 3.1.1 moves the new portrait/preset state and helpers, plus several long-lived Core constants, onto the addon namespace. The resulting `Core.lua` uses 185 chunk-level locals, preserving headroom below the 200-local limit.

## Validation completed

- `python3 scripts/validate.py` passed: `Validation passed: DK Mentor 3.1.1, Retail interface 120100`.
- Lua 5.4 compiler check passed for all 27 Lua source/test files in the source tree.
- Exact packaged runtime check passed for all 13 packaged Lua files.
- All 14 Lua smoke tests passed, including Preparation 3.1 and accessibility/preset/portrait coverage.
- Added a validator guard that fails when Core chunk-level locals exceed 190.
- Packaged `Core.lua` re-counted at 185 chunk-level locals.
- Package has exactly one top-level `DKMentor` folder.
- Package contains no `.ogg`, `.mp3`, `.wav`, `.flac`, `.m4a`, `.aac`, or `.opus` files.
- Retail interface remains `120100`.

## Preserved 3.1 systems

- Preparation / Ready Check.
- Blood, Frost 2H/Dual Wield and Unholy preparation recommendations.
- Standard / SBA-friendly Build Mentor.
- DKM31 layout preset export/import.
- Optional movable/scalable Lich King commentary portrait.
- EN / pt-BR localization.

## Package checksums

Runtime Test / Release / CurseForge package SHA-256:

`8aae496c30c0020f94fc27b883a8513e2fb0630598d69bcbc2cd8ccd3a86d224`

The GitHub source archive is built separately from the runtime package; its checksum is reported with the generated artifact rather than embedded in this report.

## Live-client limitation

Static/compiler/mocked tests cannot replace a real Retail client test. Before publication, confirm clean login/reload and exercise the four 3.1 features listed in `TESTING_v3.1.1.md`.
