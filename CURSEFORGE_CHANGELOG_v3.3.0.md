## DK Mentor 3.3.0 - Meta Pulse

- Added **DK Meta Pulse** to the Codex for Heroic Raid, Mythic+ and High Keys.
- Added observed Blood/Frost/Unholy Hero Talent usage, samples, performance snapshots and popular weapon signals from reviewed Archon.gg / Warcraft Logs data.
- Added Guide vs Logs states: ALIGNED, ALIGNED / SPLIT, SPLIT SIGNAL and META DIFFERS.
- Added optional, fail-safe **Archon Tooltip provider detection**.
- Archon installed + compatible aggregate feed: DK Mentor can use it automatically.
- Archon installed without compatible aggregate meta data: DK Mentor safely uses its built-in reviewed snapshot.
- Archon remains optional; no web requests are made from inside WoW.
- Fixed Valeera Leveling preset validation so it no longer falls back to Auto.
- Improved Codex navigation with distinct native Blizzard icons for each section.

- Added **Visual Talent Tree Mentor** to Builds: native Blizzard Class/Hero/Spec tree rendering, guide-key overlays, current/saved-loadout comparison, native tooltips, and read-only behavior.
- Recommended tree nodes use stable spell IDs and include short rationale text; flex/pathing nodes are intentionally not marked wrong.

- Improved the Visual Talent Tree layout after live testing: taller canvas, wider Class/Spec allocation, more padding, and independent horizontal/vertical fitting to prevent crowded nodes.
- Added r7 Hero-tree alignment plus **Export / Save / Saved** talent snapshot controls. DK Mentor can generate Blizzard import strings for the current compared loadout, keep reusable snapshots in SavedVariables, and let the player copy them again later without auto-applying talents.

- r8 fixes false Visual Talent Tree key counts by using Blizzard `nodeID` / `entryID` / spell-ID aliases and Hero `subTreeID` instead of localized talent names or rank-only checks.
- Added **Create in WoW** for fully aligned current-spec builds: DK Mentor can create a separate saved Blizzard talent loadout directly from the complete compared import string without auto-activating it.
- Saved DK Mentor talent snapshots can also be recreated directly in Blizzard Talents; export/copy remains available as a fallback.

- **Guide-key diagnostics (r9):** Build Mentor now names each key-node state (OK / MISSING / SWAP / NOT MAPPED) and explains exactly why Create in WoW is blocked.
