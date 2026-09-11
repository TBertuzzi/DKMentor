# Validation Report - DK Mentor 1.0.19

- Version metadata synchronized with Retail Interface 120100.
- Managed aura HUD lock is now interaction-only; it no longer makes the host frame transparent.
- Added a static regression guard requiring the managed-aura label/chrome to remain visible while the lock only controls mouse interaction.
- Confirmed the DK Buffs native AuraContainer path, Preview hard override, combat-only visibility, configurable bar sizing, and 1.0.18 cooldown-helper order guard remain present.
- Lua syntax and release ZIP integrity are validated during packaging in this environment.

## Live-client limitation

This environment does not run the World of Warcraft client. Final Blizzard AuraContainer behavior must still be verified in the live 12.1.0 client using `TESTING_v1.0.19.md`.
