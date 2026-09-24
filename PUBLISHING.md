# Publishing DK Mentor 3.3.2

DK Mentor 3.3.2 is a focused post-September-22 tuning guidance refresh. It preserves the 3.3.1 feature set and updates only source-backed DK/Valeera guidance, data freshness, and review metadata.

## Before publishing

1. Run `python3 scripts/validate.py`.
2. Run all Lua smoke tests available in `tests/`.
3. Complete `TESTING_v3.3.2.md` in the live Retail client, especially the new Unholy San'layn Blightfall raid Alternative and the REVIEW PENDING states.
4. Re-check Blizzard hotfixes and the Wowhead/Icy Veins talent pages immediately before upload. If they publish a post-tuning ranking, update the affected profile before release rather than publishing stale provisional wording.
5. Confirm the final CurseForge ZIP contains one top-level `DKMentor/` directory.
6. Confirm the source archive excludes generated `release/` staging content.

## CurseForge

Upload `DKMentor-v3.3.2-CurseForge.zip` after live validation.

Suggested display name: `DK Mentor 3.3.2 - Post-Tuning DK Guidance`

Use `CURSEFORGE_CHANGELOG_v3.3.2.md` as the file changelog.

## GitHub

Tag: `v3.3.2`

Suggested release title: `DK Mentor 3.3.2 - Post-Tuning DK Guidance`

Use `RELEASE_NOTES_v3.3.2.md` as the GitHub release body.
