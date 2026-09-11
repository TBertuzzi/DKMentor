# DK Mentor 1.0.16

This build fixes the two problems visible in the 1.0.15 live screenshot: too few DK buffs/procs compared with Blizzard's Cooldown Manager, and combat HUDs remaining visible after combat.

## DK Buffs architecture

On Retail 12.1, aura presence and timing can become secret during combat. 1.0.15 still tried to reconstruct the active DK buff list from readable aura data, proc events, and materialized Cooldown Viewer frames. That could never reach reliable parity with Blizzard's own display.

1.0.16 moves the primary DK Buffs HUD to Blizzard's `AuraContainer`/`AuraGroup` engine. DK Mentor supplies a curated `includeSpellIDs` whitelist; Blizzard securely decides which effects are active and drives icon, stack, and duration state. The older manual renderer remains only as a compatibility fallback.

The whitelist combines DK Mentor's important spec buffs with spell/override IDs resolved from the current Frost Max Buff Tracking, Frost Khazak, Unholy Taeznak/Luxthos, and Blood Luxthos/Quick Start Cooldown Manager profiles.

## Visibility regression

`Bars only in combat` is restored as the default/migrated behavior. Existing databases from earlier schemas are repaired once. Combat end now hides the combat HUDs immediately, heals a stale combat latch when public combat state confirms combat ended, and rechecks visibility after the transition.

## Season 2 additions

- Blood: Blood Debt and Relentless Rider's Strength.
- Unholy: Icy Talons added to the important-buff fallback.
- Frost: existing Max Buff Tracking / Khazak profile integration is retained and now feeds the native AuraContainer whitelist instead of a manual active-state guess.
