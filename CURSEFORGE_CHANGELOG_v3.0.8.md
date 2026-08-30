# DK Mentor 3.0.8

### Fixed

- Action Bar coverage now respects the active Death Knight specialization and currently known talents/spells.
- Frost and Blood are no longer asked to place Unholy-only Soul Reaper on their action bars.
- Active spell overrides remain supported when checking action-bar coverage.
- Replaced the Review `Overview -> Timeline -> Patterns` decorative arrows with font-safe separators, fixing square/missing-glyph boxes on affected WoW fonts.

### Safety

- Added regression tests for cross-spec Assisted Combat spell leakage and unsupported decorative UI glyphs.
- No SavedVariables schema changes.
- No automatic casting or targeting.
