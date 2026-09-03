# DK Mentor 2.0.10 — Release Candidate

DK Mentor 2.0.10 is the final polish candidate for the 2.0 public release. No new combat subsystem was added; this build focuses on upgrade safety, recoverability, alert preview, defaults, and release messaging.

## Release-candidate polish

- Added **Reset HUD positions** to the Settings HUD section so misplaced combat HUDs can be restored without deleting SavedVariables.
- Added **Reset Mentor settings** to Adaptive DK Coach. It restores Mentor mode and all 2.0 coaching toggles while keeping the most recent combat report.
- Added **Test alerts** to Adaptive DK Coach. Outside combat it previews Defensive, Proc, Resource, and Mind Freeze visuals for eight seconds using the actual coach / interrupt HUD locations.
- Added `/dkm mentor test` and `/dkm mentor reset` aliases.
- Confirmed the default experience remains **Mentor** intensity with Combat Insights and the compact post-combat popup enabled.
- Added a one-time 2.0 upgrade notice explaining that loadout automation moved to Loadout Pilot and that DK Mentor only recommends actions; it never casts abilities automatically.
- Added a migration guard for stale 1.x / early-2.0 HUD anchors, coordinates, scale, and opacity so malformed SavedVariables cannot strand panels far off-screen.
- HUD edit mode still starts locked every login/reload.
- Existing legacy loadout mapping tables remain preserved for rollback safety but inactive.

## Preserved 2.0 systems

- Adaptive DK Coach: Essential / Mentor / Training.
- Defensive Advisor.
- Interrupt / Utility Coach with Midnight Secret-safe Mind Freeze presentation.
- Resource and proc waste coaching.
- Blood/Frost/Unholy spec-aware guidance.
- Solo / Delves emphasis.
- Combat Insights and DK Mentor Score.
- DK Codex and Character Check.
- DK Ready.
- Buff, external buff, debuff, ability, resource, and arc HUDs.
- Dynamic compact post-combat popup.
- Midnight 12.1 protected-value safeguards.

## Database

SavedVariables schema is now **30**. The migration is deliberately small and non-destructive: valid existing settings are preserved, legacy loadout data is not deleted, and only malformed/stale HUD placement values are normalized.

## Release gate

Treat 2.0.10 as the release candidate. Run the live checklist in `TESTING_v2.0.10.md`. If no critical regression appears, the same 2.0.10 code can be promoted to the stable CurseForge/GitHub release.
