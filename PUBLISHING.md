# Publishing DK Mentor 3.1.6

DK Mentor 3.1.6 is the public 3.1 release. It combines Preparation / Ready Check, SBA-friendly guidance, DKM31 layout presets, the optional Arthas/Bolvar Lich King portrait, live-test UI fixes, and the September 3 Season 2 guidance refresh.

## Before publishing
1. Run `python3 scripts/validate.py`.
2. Run the available Lua/static smoke tests.
3. Confirm the final CurseForge ZIP contains one top-level `DKMentor/` directory.
4. Confirm the final GitHub archive contains the source tree and documentation but not generated release staging folders.
5. Confirm the live-tested 3.1.6 r4 behavior is preserved.

## CurseForge
Upload `DKMentor-v3.1.6-CurseForge.zip`.

Suggested display name: `DK Mentor 3.1.6 - Preparation, Presets & Lich King Portrait`

Use `CURSEFORGE_CHANGELOG_v3.1.6.md` as the file changelog.

## GitHub
Tag: `v3.1.6`

Suggested release title: `DK Mentor 3.1.6 - Preparation, Presets & Lich King Portrait`

Use `RELEASE_NOTES_v3.1.6.md` as the GitHub release body.
