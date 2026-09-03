# DK Mentor 3.0.9 - Mind Freeze Action-Bar Glow & Interrupt Sound

Version 3.0.9 keeps DK Mentor's existing Midnight-safe interrupt detection intact and adds two optional presentation layers for Death Knights: a Mind Freeze action-bar glow and a lightweight interrupt sound.

## Mind Freeze action-bar glow

When the existing DK Mentor interrupt engine detects a target cast/channel and Mind Freeze is available, DK Mentor can now outline the matching Mind Freeze action button with a small cyan pulse.

The implementation supports:

- direct Mind Freeze spell buttons;
- macros whose current macro spell resolves to Mind Freeze;
- Blizzard action bars and buttons registered with the Blizzard action-button event frame;
- normal action-bar changes/spec/talent refreshes outside combat.

The glow does not replace DK Mentor's existing interrupt HUD. It is an independent visual helper and can be disabled at any time.

The addon uses its own lightweight border instead of taking ownership of Blizzard's proc overlay, avoiding interference with native spell/proc highlights.

## Midnight Secret Value safety

The interrupt engine itself is unchanged. If `notInterruptible` is protected by Midnight, DK Mentor still does not inspect or branch on that value in Lua. The protected boolean is passed directly to a widget through `SetAlphaFromBoolean`, so the action-bar glow follows the same Secret-safe presentation model as the existing Mind Freeze HUD.

If a readable Mind Freeze cooldown confirms the ability is unavailable, the action-bar glow is suppressed. If availability is restricted, DK Mentor avoids inventing hidden state.

## Configurable interrupt sound

Interrupt sound is optional and defaults to OFF.

DK Mentor reuses one Blizzard-installed `RAID_WARNING` sound and does not bundle an audio library, keeping the addon package small. The sound is emitted once for a new interrupt window instead of repeating on the 120 ms interrupt refresh heartbeat.

## Configuration

- Settings -> `Interrupt options...` opens Alert Studio directly on Interrupt.
- Alert Studio -> `Action glow: ON/OFF`.
- Alert Studio -> `Sound: ON/OFF` while Interrupt is selected.
- `/dkm interrupt glow on|off`
- `/dkm interrupt sound on|off`
- `/dkm interrupt options`
- `/dkm interrupt status` remains available for diagnostics.

## Defaults

- Existing Mind Freeze HUD: unchanged.
- Action-bar glow: ON.
- Interrupt sound: OFF.
- No bundled sound files.

## Unchanged

- Existing interrupt detection and Secret Value handling.
- Adaptive Coach / Next Action / Review / Patterns.
- DK Tools and HUD layouts.
- SavedVariables schema 31.
- Setup Wizard schema 301.

DK Mentor remains guidance-only and never casts abilities or selects targets automatically.
