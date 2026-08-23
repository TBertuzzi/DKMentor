# DK Mentor 1.0.21

## HUD appearance polish

This release focuses on interface customization without changing combat recommendations or the working DK Buffs/AuraContainer tracking path.

### What is new

- Independent **30%-100% opacity** for DK Buffs, External Buffs, Debuffs, Abilities, and DK Resources.
- Larger **HUD appearance** window with Size, Opacity, and Icons/Mode controls.
- DK Resources can hide the **Runic Power label and numeric text** while keeping the native status-bar fill.
- Rune segment spacing can be switched between **Compact**, **Normal**, and **Wide**.
- **Restore DK Resources** resets only the resource HUD and leaves the other HUDs unchanged.
- Settings now shows a compact summary of the active DK Resources mode, text state, and Rune spacing.
- Global **Restore HUD appearance** resets combat-HUD scale/opacity/row-width defaults without moving HUD positions.

### Compatibility

The 1.0.16+ Blizzard AuraContainer implementation for DK Buffs is unchanged. HUD locking remains interaction-only. Preview remains a hard out-of-combat layout override. Runic Power still follows the secret-safe native StatusBar path introduced in 1.0.20.
