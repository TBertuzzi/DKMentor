## DK Mentor 2.0.6

- Fixed a Midnight `ADDON_ACTION_FORBIDDEN` error during addon load.
- Removed forbidden `COMBAT_LOG_EVENT_UNFILTERED` / `CombatLogGetCurrentEventInfo` dependencies from Adaptive DK Coach.
- Recent defensive pressure now uses safe player-health deltas instead of combat-log damage events.
- Mind Freeze / interrupt scoring now uses unit spellcast events only.
- Improved Blood Bone Shield refresh without combat-log parsing.
- Added validation guards preventing the forbidden combat-log path from returning.
- SavedVariables schema remains 29.
