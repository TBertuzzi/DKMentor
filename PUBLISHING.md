# Publishing DK Mentor 1.0.9

## GitHub

1. Create an empty public repository named `DKMentor`.
2. Extract `DKMentor-v1.0.9-GitHub.zip` into the repository root.
3. Commit and push to `main`.
4. Keep the included MIT license, third-party notices, policy document, and README.
5. The repository includes validation and release workflows under `.github/workflows/`.

Example first commit:

```bash
git init
git add .
git commit -m "Release DK Mentor 1.0.9"
git branch -M main
git remote add origin YOUR_REPOSITORY_URL
git push -u origin main
```

## CurseForge manual first release

1. Create the DK Mentor project using `CURSEFORGE_SUBMISSION.md`.
2. Use `CURSEFORGE_DESCRIPTION.md` for the project description.
3. Upload `DKMentor-v1.0.9-CurseForge.zip` as the game file.
4. For the first public upload, **Beta** is recommended until broader live-client testing is complete.
5. The ZIP must contain one top-level `DKMentor` directory and no repository-only files.

## Automated CurseForge releases after project approval

Once CurseForge assigns a numeric project ID:

1. Add `## X-Curse-Project-ID: PROJECT_ID` to `DKMentor.toc`.
2. Add a GitHub Actions repository secret named `CF_API_TOKEN`.
3. Push the TOC update.
4. Tag future releases using `vX.Y.Z`.

The included release workflow uses `BigWigsMods/packager@v2` and the repository's `.pkgmeta` rules.

## Release checklist

- Test login on Blood, Frost, and Unholy.
- Test World, Delve, Dungeon, Raid, and PvP context detection.
- Test Assisted Combat highlight and the Survival Coach.
- Verify DK Buffs, External Buffs, Debuffs, and Ability HUDs in and out of combat.
- Verify the Combat only / Always visibility switch hides and restores all four bars at combat transitions.
- Verify External Buff/Debuff wrapping after more than five simultaneous auras.
- Verify HUD lock, preview, movement, and reset.
- Verify talent and equipment mapping/automatic switching when allowed.
- Verify minimap button positioning on the current Edit Mode minimap size.
- Test the optional voice system with Dialog sound enabled.
- Check `/reload` persistence.
- Confirm no Lua errors with other addons disabled.
- Confirm the release ZIP contains no audio files, third-party talent strings, copied guide text, or unrelated source-repository files.
