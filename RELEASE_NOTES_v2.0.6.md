# DK Mentor 2.0.6 — Midnight combat-log hotfix

Version 2.0.6 fixes a load-time `ADDON_ACTION_FORBIDDEN` introduced by the new Adaptive DK Coach in 2.0.5.

## What happened

The first Adaptive Coach build registered `COMBAT_LOG_EVENT_UNFILTERED` to collect recent damage, aura, and interrupt details. Midnight no longer exposes that combat-log event to normal third-party addons. Registering it can raise an addon-forbidden popup before the module finishes loading.

## Fix

- Removed `COMBAT_LOG_EVENT_UNFILTERED` registration entirely.
- Removed `CombatLogGetCurrentEventInfo` usage entirely.
- Recent incoming pressure is inferred from the player's own readable health deltas over the existing five-second window.
- Damage school is not guessed, so the Coach will not claim magic-pressure knowledge it does not have.
- Personal Mind Freeze handling is detected from `UNIT_SPELLCAST_SUCCEEDED` while an interruptible target-cast window is active.
- `UNIT_SPELLCAST_INTERRUPTED` marks the tracked target opportunity as handled even when another player interrupted it.
- Blood Bone Shield refreshes through the player-owned aura API.
- Target aura coaching remains conservative under Midnight restrictions and is skipped when target aura state is not safely readable.

## Regression protection

The validator and MentorEngine smoke test now explicitly reject any future runtime use of the forbidden Midnight combat-log event/API.

SavedVariables schema remains 29.
