# Validation Report - DK Mentor 1.0.15

- Version metadata synchronized with Retail Interface 120100.
- Wowhead Cooldown Manager profile ID tables present for Blood, Frost, and Unholy.
- Direct `C_CooldownViewer.GetCooldownViewerCooldownInfo` calls are prohibited by validation; cached Blizzard provider/frame data is used instead.
- Active mirror state no longer relies on the generic Cooldown Viewer `IsActive()` configuration state.
- Midnight proc fallbacks present for all three Death Knight specs.
- Secret-value guards retained for PvP/restricted data.
- Combat automation API blacklist retained.
- War Mode experiment remains absent.
