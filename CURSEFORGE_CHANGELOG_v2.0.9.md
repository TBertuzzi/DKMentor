## DK Mentor 2.0.9

- Fixed the Mind Freeze interrupt indicator in Midnight restricted combat.
- Interruptibility now uses WoW 12.x's Secret-safe UI pass-through path (`SetAlphaFromBoolean`) rather than requiring Lua to read the protected boolean.
- Keeps target interruptibility events as transition fallbacks and adds a lightweight cast-state heartbeat for restricted event payloads.
- Interrupt icon is click-through during normal gameplay.
- Added `/dkm interrupt status` for safe troubleshooting.
- Preserves Adaptive Coach, dynamic Combat Insights, click-through resource HUD and active-only aura HUD behavior.
