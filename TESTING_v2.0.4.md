# DK Mentor 2.0.4 live test

## Mind Freeze alert

1. In **Settings > Combat HUD**, confirm **Interrupt alert** is ON.
2. Enable **show combat bars only in combat** if you normally use that option.
3. Target an enemy that performs a normal interruptible cast. The Mind Freeze icon should appear as soon as the cast becomes interruptible.
4. Let the cast finish or interrupt it. The icon must disappear.
5. Test a cast with the shield / non-interruptible state. The icon must remain hidden, or disappear immediately if the cast changes to non-interruptible.
6. Test an interruptible channel. The icon should remain visible for the interruptible portion of the channel.
7. Change targets while a cast is running and confirm the alert follows only the current target.
8. Put Mind Freeze on cooldown and repeat: the alert may show its cooldown/dimmed state, but must never attempt to cast it.
9. Use **HUD Preview** to confirm the alert frame still exists and can be positioned while HUDs are unlocked.
10. Watch for Lua errors, taint, blocked actions, or secret-value errors during all tests.

## Regression

- Enemies remain clickable through the health/runic-power arc HUD.
- Empty DK Buffs / External Buffs / Debuffs containers remain invisible outside HUD Preview.
- Compact DK status widget remains small and functional.
- DK Codex source URL row remains correctly sized.
