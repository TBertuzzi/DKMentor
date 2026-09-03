# Validation Report - DK Mentor 1.0.16

- Version metadata synchronized with Retail Interface 120100.
- Settings schema bumped to 21 with combat-only HUD migration enabled.
- Primary DK Buffs path uses Blizzard `AuraContainer` with an `includeSpellIDs` candidate filter.
- AuraContainer initialization order is `SetUnit` -> `AddAuraGroup` -> `SetEnabled` and keeps native `UpdateAllAuras` support.
- Cooldown Manager profile integration remains read-only and resolves Blizzard provider spell/link/override IDs without importing or changing the player's UI profile.
- Native candidate-filter refresh is deferred while in combat and replayed after `PLAYER_REGEN_ENABLED`.
- Blood Debt (1310372), Relentless Rider's Strength (1300369), and Unholy Icy Talons fallback tracking are present.
- Legacy manual aura/proc/mirror logic is retained only as a fallback when AuraContainer is unavailable.
- Combat-exit hiding now includes immediate, next-frame, and delayed state/visibility checks.
- Secret-value guards and combat-automation API blacklist remain enabled.
- Static validation passed; final confirmation of secure AuraContainer behavior still requires the live WoW 12.1 client.
