# Validation Report - DK Mentor 1.2.3

Date: 2026-08-25
Target: World of Warcraft Retail 12.1.0 / Interface 120100

## Completed checks

- Confirmed `DKMentor.toc` and `Data.lua` report version `1.2.3`.
- Parsed `Localization.lua`, `Data.lua`, `Builds.lua`, `Guides.lua`, `Voices.lua`, and `Core.lua` successfully with `texluac -p`.
- Ran `scripts/validate.py` successfully.
- Confirmed manual and automatic specialization requests prefer `C_SpecializationInfo.SetSpecialization`, with the ClassTalents specialization API retained as fallback.
- Confirmed the automatic duplicate-attempt throttle is 2 seconds instead of 4 seconds.
- Confirmed transient automatic specialization failures keep a pending target and schedule a retry rather than abandoning the mapping immediately.
- Confirmed the first post-world automatic profile is scheduled independently from the existing four-second aura/voice/cache refresh.
- Confirmed the post-`PLAYER_SPECIALIZATION_CHANGED` profile follow-up is 0.5 seconds.
- Confirmed the compact Build HUD handles right-click by toggling the DK Mentor main window.
- Confirmed the specialization icon still handles left-click for the Blood/Frost/Unholy picker and right-click for the main DK Mentor window.
- Confirmed the schema-29 `DeepCopy` migration hotfix from 1.2.2 remains guarded.
- Confirmed Dungeon/Mythic+ unified overrides, Loot Specialization, picker layering, role protection, equipment retry behavior, and six DK Arc textures remain present.

## Package checks

- CurseForge archive contains exactly one top-level `DKMentor` folder.
- Test archive contains exactly one top-level `DKMentor` folder.
- CurseForge archive contains all six DK Arc textures.
- Test archive contains all six DK Arc textures.
- ZIP integrity checks passed for CurseForge and Test packages.

CurseForge SHA-256: `1b4fffda86bd53ed7295d1f0eac7d2d3e0aea93a5a04f1acc6bf093014fa0537`

Test SHA-256: `e1a719de01316cb940f557492d750c61b070f151cc26a5f543c7133a7d210387`

## Live-client limitation

Static validation cannot make the Blizzard client change specialization faster and cannot prove the timing of protected/transitional API behavior in the live game. Before publishing, verify the first post-login/profile switch, one World/Delve or World/Dungeon specialization transition, one transient retry scenario if reproducible, and both left/right-click Build HUD interactions in Retail 12.1.0.
