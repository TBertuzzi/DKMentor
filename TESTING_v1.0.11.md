# DK Mentor 1.0.11 live test

## Buff/proc bar

- Enable **DK Buffs** in Settings.
- On Frost, trigger Killing Machine and Rime repeatedly and confirm proc-related icons react during combat.
- If another talent proc makes a Blizzard action button glow, confirm a transient gold-bordered proc icon can appear.
- Confirm the DK Buff Bar wraps after five icons instead of becoming a long horizontal row.
- If available, test Blood Crimson Scourge/Hemostasis and Unholy Runic Corruption/Sudden Doom.

## Interrupt alert

- Keep **Interrupt alert** enabled.
- Target an NPC with an interruptible cast and confirm the Mind Freeze icon appears only while the cast/channel is interruptible.
- Target or observe an uninterruptible cast and confirm the icon stays hidden.
- Put Mind Freeze on cooldown and confirm the alert can show its cooldown/dimmed state without attempting to cast anything.
- Use HUD Preview + Unlock to move the alert, then Lock and `/reload` to confirm its position persists.
- Test at least one PvP/training target and confirm no `secret value`, taint, or protected-action error is generated.

## Regression

- World -> PvP -> World still updates the HUD context automatically.
- Automatic talent/equipment switching still follows the detected context.
- No War Mode UI/API logic is present.
