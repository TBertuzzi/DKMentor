# DK Mentor 3.0.9 validation report

## Automated validation

- `python3 scripts/validate.py`: PASS - DK Mentor 3.0.9 / Retail interface 120100.
- Runtime Lua syntax (`texluac -p`): PASS for all 11 runtime Lua files.
- `tests/codex_smoke.lua`: PASS.
- `tests/localization_smoke.lua`: PASS.
- `tests/mentor_engine_smoke.lua`: PASS.
- `tests/review_smoke.lua`: PASS.
- `tests/tools_smoke.lua`: PASS.
- `tests/studio_smoke.lua`: PASS.
- `tests/core_ux_smoke.lua`: PASS.
- `tests/modal_navigation_smoke.lua`: PASS.
- `tests/interrupt_enhancements_smoke.lua`: PASS.

## 3.0.9 interrupt regression guards

- Existing Mind Freeze interrupt detector remains the source of truth.
- Action glow is optional and defaults ON.
- Interrupt sound uses the existing Alert Studio per-kind setting and defaults OFF.
- Direct spell actions and macros resolving to Mind Freeze are supported.
- Cached buttons are re-checked before display so a slot that no longer resolves to Mind Freeze is not highlighted.
- Secret `notInterruptible` is passed through `SetAlphaFromBoolean` without Lua comparison.
- The custom glow does not call Blizzard `ActionButton_ShowOverlayGlow` / `ActionButton_HideOverlayGlow`.
- Interrupt notification is gated to one new interrupt window so the 120 ms refresh heartbeat does not repeat the sound.
- No external/bundled sound file was added.
- SavedVariables schema remains 31; Setup Wizard schema remains 301.

## Live-client boundary

Automated tests cannot reproduce real Retail 12.1 combat restrictions, protected action-button behavior, dynamic macro resolution, or Secret Value timing. Complete `TESTING_v3.0.9.md` in the live WoW client before promoting the build from test/beta to final release.

## Package verification

The Test, Release, CurseForge, and GitHub archives were unpacked after creation. All runtime Lua files parsed successfully from every archive, and the complete validator + smoke-test suite passed again from the unpacked GitHub package.

Selected runtime SHA-256 values were identical across all four package variants:

- `DKMentor.toc`: `06e174f9aca4a9ed0f9f8e6f74a4590b52290037960631428ea212ec642cd430`
- `Core.lua`: `3abc13bf3e005228177fe1f1924ad2c54990a0ed14b5c52683b2df9a08148b59`
- `MentorEngine.lua`: `84cc299e72f6bf2d0c7c4bf1d2ccbb034e9e496a5b7e83b524d0fbd6eca421ca`
- `MentorStudio.lua`: `34c345a9ef2134892f19584161d2715950d730bc03569af5ab6d0b6662892e84`
- `Localization.lua`: `6065b82d3fb792c39f1d14f83962586096f2b30145c1d573779c5da7481d13b2`
- `Data.lua`: `bfa86278dc4fa8272e268b89212b49979c81ab715664f9dcdb3dd70cef5b2067`
- `MentorReview.lua`: `b90d2674db2612417045eb696b119876a0459cf62b13ce1c5df8f2fe0b696a16`
- `DKTools.lua`: `3e899e18d303690fbfd6725570d1cdffe7eb7786f4682714140699a27b8d7486`
