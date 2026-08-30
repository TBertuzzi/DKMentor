# DK Mentor 3.0.9

### Added

- Optional cyan **Mind Freeze action-bar glow** when DK Mentor's existing interrupt engine confirms a valid interrupt window.
- Direct spell-button and Mind Freeze macro support.
- Optional interrupt sound using one Blizzard-installed sound; OFF by default and no audio files are bundled.
- `Interrupt options...` shortcut from Settings to Alert Studio.
- `/dkm interrupt glow on|off`, `/dkm interrupt sound on|off`, and `/dkm interrupt options`.

### Safety / behavior

- Existing Midnight Secret-safe interrupt detection remains unchanged.
- Protected interruptibility values continue to flow directly into `SetAlphaFromBoolean` without Lua inspection.
- Interrupt sound fires once per new interrupt window, not on the 120 ms refresh heartbeat.
- The custom action glow does not replace Blizzard's native proc-overlay state.
- No automatic casting or targeting.
- No SavedVariables schema changes.
