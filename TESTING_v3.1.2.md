# DK Mentor 3.1.2 — Live Test Checklist

## 1. Startup
- Install 3.1.2 Test over 3.1.1 and `/reload`.
- Confirm no Lua warnings/errors and DK Mentor loads normally.

## 2. Preparation enchant status
- Open DK Codex -> Equipment -> Preparation.
- Confirm equipped enchanted Head/Shoulders/Chest/Legs/Feet/Rings resolve to APPLIED instead of remaining on CHECKING.
- Confirm a genuinely unenchanted supported slot resolves to MISSING.
- Swap/equip an item and confirm the open Preparation page refreshes.

## 3. Frost Runeforge
- Frost 2H: confirm only the two-hand Fallen Crusader recommendation is shown.
- Frost dual wield: confirm two cards appear in this order: Main hand, Off hand.
- With Shattering Blade known: Main hand should recommend Razorice; Off hand should recommend Fallen Crusader.
- Without Shattering Blade: Main hand should recommend Stoneskin Gargoyle; Off hand should recommend Fallen Crusader.
- Confirm APPLIED is evaluated against the correct weapon slot.

## 4. Lich King portrait
- Enable commentary and portrait.
- Use voice preview or trigger a commentary line.
- Confirm the 3D Lich King visibly animates while the voice is playing.
- Confirm he returns to idle / the portrait closes after playback according to the existing lock/preview behavior.
- Unlock, move, scale, lock, `/reload`, and confirm the saved layout persists.

## 5. Regression
- Test Blood and Unholy Preparation.
- Confirm Gear Mentor, Build Mentor, SBA-friendly mode, presets, HUDs, and commentary still work.
