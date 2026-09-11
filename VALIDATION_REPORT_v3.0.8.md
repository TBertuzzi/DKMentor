# DK Mentor 3.0.8 validation report

Automated validation status: **PASS**

- `python3 scripts/validate.py`: PASS (`DK Mentor 3.0.8`, Retail interface `120100`)
- All 11 runtime Lua files parsed successfully with `texluac -p`
- `tests/codex_smoke.lua`: PASS
- `tests/core_ux_smoke.lua`: PASS
- `tests/localization_smoke.lua`: PASS
- `tests/mentor_engine_smoke.lua`: PASS
- `tests/modal_navigation_smoke.lua`: PASS
- `tests/review_smoke.lua`: PASS
- `tests/studio_smoke.lua`: PASS
- `tests/tools_smoke.lua`: PASS
- Runtime scan found none of the known unsupported decorative glyphs (`checkmark`, arrow, triangles/squares/diamonds) guarded by 3.0.8 validation.
- Static regression coverage confirms `CheckActionBarCoverage()` uses the active-spec/known-spell filtered Assisted Combat list and explicitly restricts Soul Reaper (343294) to Unholy.
- All four generated packages were extracted successfully.
- Runtime files are SHA-256 identical across Test, Release, CurseForge, and GitHub packages.

## Runtime SHA-256

- `Core.lua`: `cf59b5835d976defa9f40024a2303d08fad02b7271ea47e6f54a9e5d2ef35957`
- `Data.lua`: `9338dcb236de378d0a3a1782b3f22891540d2b1ee91a617a54c3ee6794c1e6b6`
- `Localization.lua`: `7ff317d955fcf662e6e44fbbfbe213920d296e85466a7a4e75fd7c85e6d30f7f`
- `MentorEngine.lua`: `37a64c2339531b791d1f25d7c1e7ba0f2e82d3256ca4a4f9a3a53fa2621e5bea`
- `MentorReview.lua`: `b90d2674db2612417045eb696b119876a0459cf62b13ce1c5df8f2fe0b696a16`
- `MentorStudio.lua`: `d9415d80d6c88e892b3e3c0be2bc1a0efd80abd1a11958fe9e93a6d95a37dcd1`
- `DKTools.lua`: `3e899e18d303690fbfd6725570d1cdffe7eb7786f4682714140699a27b8d7486`
- `DKMentor.toc`: `a847c13232af765518063676ae184c18b57d1bd523713b78135253ef91099d82`

## Live-client checks still required

Offline tests cannot reproduce Blizzard's live Assisted Combat refresh timing, Secret Values, or the exact font rendering path. Complete `TESTING_v3.0.8.md` in Retail 12.1 before publishing.
