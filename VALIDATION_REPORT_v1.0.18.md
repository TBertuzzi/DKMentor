# Validation Report - DK Mentor 1.0.18

- Version metadata synchronized with Retail Interface 120100.
- Added a static regression guard requiring `ClearTrackingCooldown` to be declared before managed-aura runtime/preview helpers.
- Confirmed the DK Buffs `AuraContainer` path and candidate-filter whitelist are still present.
- Confirmed Preview hard-override and configurable combat-bar layout controls are still present.
- Lua syntax and release ZIP integrity are validated during packaging in this environment.

## Live-client limitation

This environment does not run the World of Warcraft client. Final behavior of Blizzard-owned `AuraContainer` frames must still be verified in the live 12.1.0 client using `TESTING_v1.0.18.md`.
