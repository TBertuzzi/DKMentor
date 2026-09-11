# Validation Report — DK Mentor 1.3.4

Date: 2026-08-25

## Completed checks

- Confirmed Retail 12.1 / Interface 120100 metadata and version 1.3.4.
- `texluac -p` passed for Localization.lua, Data.lua, Builds.lua, Guides.lua, Codex.lua, Voices.lua, and Core.lua.
- `scripts/validate.py` passed with the existing Midnight secret-aspect, Loadouts 2.x, DK Codex, and schema-migration regression guards.
- Added static regression guards for the managed-loadout refresh path: Blizzard import decoding, specialization/tree/version validation, exact DKM-managed-name restriction, asynchronous replacement handling, selected-loadout restoration, and action-bar-sharing preservation.
- SavedVariables schema remains 29; no database migration is introduced.
- Arbitrary player-named loadouts are excluded from the automatic overwrite path.

## Live-client verification still required

The WoW client owns the final behavior of `C_ClassTalents.ImportLoadout` and may complete the import synchronously, asynchronously, or by replacing the saved config ID. The code handles both in-place and replacement completion paths, but the Frost/Raid `DKM Raid` overwrite flow must still be verified in the live Retail 12.1 client before publication.
