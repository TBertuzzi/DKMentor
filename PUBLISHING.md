# Publishing DK Mentor 3.2.0

DK Mentor 3.2.0 adds the DK-specific Stats & Folio Advisor, Gear Targets 2.0, and Valeera Delve Mentor while preserving the complete 3.1.6 feature/fix set.

## Before publishing
1. Run `python3 scripts/validate.py`.
2. Complete `TESTING_v3.2.0.md` in the live Retail client, especially Stats/Folio detection, Catalyst panels, smart tooltips, and 3.1.6 regressions.
3. Confirm the final CurseForge ZIP contains one top-level `DKMentor/` directory.
4. Confirm the final GitHub/source archive contains source and documentation but not generated release staging folders.
5. Re-check CURRENT / REVIEW PENDING data immediately before publishing if Blizzard or DK guide authors publish a new tuning/build update.

## CurseForge
Upload `DKMentor-v3.2.0-CurseForge.zip` after live validation.

Suggested display name: `DK Mentor 3.2.0 - Stats, Folio, Gear Targets 2.0 DK Mentor 3.2.0 - Stats, Folio & Gear Targets 2.0 Valeera Mentor`

Use `CURSEFORGE_CHANGELOG_v3.2.0.md` as the file changelog.

## GitHub
Tag: `v3.2.0`

Suggested release title: `DK Mentor 3.2.0 - Stats, Folio, Gear Targets 2.0 DK Mentor 3.2.0 - Stats, Folio & Gear Targets 2.0 Valeera Mentor`

Use `RELEASE_NOTES_v3.2.0.md` as the GitHub release body.
