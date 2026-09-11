# Validation report — DK Mentor 1.0.3

Date: 2026-08-22
Target: World of Warcraft Retail 12.1.0 / Interface 120100

## Static/package checks

- TOC and Data version synchronized at 1.0.3.
- Repository policy validator passes.
- Runeforge metadata includes the current DK enchant IDs used by the Ready Check.
- `/dkm ready` and ptBR Ready Check localization are present.
- CurseForge package contains one top-level `DKMentor` folder.
- GitHub package contains the full source/repository files.
- No bundled audio files, third-party addon code, or third-party talent import strings.

## 1.0 behavior to verify in the live client

- Automatic talent change still updates Blizzard's native saved-loadout selector and clears TALENTS QUEUED.
- Automatic Equipment Set change is reflected by the Ready Check.
- Runeforge Guard identifies main-hand and off-hand DK runes correctly after login, equipment swap, and applying a new Runeforge.
- Unholy Ghoul Guard changes immediately when the pet is summoned, dismissed, or dies.
- Vehicle/taxi suppression avoids false ghoul warnings.
- Build HUD remains readable at common UI scales in enUS and ptBR.
- `/dkm ready` matches the Build HUD tooltip.

## Important live-client limitation

This environment cannot run the World of Warcraft client. The 1.0.3 Test package should be exercised for several days before the CurseForge upload, especially across World, Delves, Dungeons, Raids, PvP, dual-wield Frost, and Unholy pet transitions.


Additional 1.0.3 verification: checked TOC icon metadata, synchronized versions, and validated the compact HUD layout code path.


Additional 1.0.3 verification: checked the dynamic-height calculation, including minimum/maximum bounds and wrapped-text growth.


Additional 1.0.3 verification: added a player-initiated specialization picker using Blizzard specialization APIs, blocked the action during combat, and preserved the existing post-specialization talent/equipment automation path.
