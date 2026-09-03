# DK Mentor 3.1.3 — Live Test Checklist

## 1. Startup
- Install **3.1.3 Test** over 3.1.2 and `/reload`.
- Confirm no Lua warning/error and normal addon startup.

## 2. Portrait character selector
- Open Settings -> Lich King commentary.
- Confirm **Portrait character: Arthas** is shown for a fresh/default profile.
- Click the button and confirm it changes to **Bolvar**.
- Click again and confirm it returns to **Arthas**.
- Confirm the portrait title follows the selected character.

## 3. Arthas model
- Select Arthas, unlock the portrait and preview/show it.
- Confirm the Icecrown Lich King model appears.
- Trigger/preview commentary and confirm the talking animation continues during playback.

## 4. Bolvar model
- Select Bolvar, unlock the portrait and preview/show it.
- Confirm Bolvar-as-Lich-King appears rather than Arthas.
- Trigger/preview commentary and confirm the model attempts the same talking animation and safely falls back if that animation is unavailable for the creature model.

## 5. Persistence
- Select Bolvar, `/reload`, and confirm Bolvar remains selected.
- Export a DKM31 layout preset while Bolvar is selected.
- Switch to Arthas, import that preset, and confirm Bolvar is restored.
- Import an older 3.1 preset without the character field and confirm it remains valid.

## 6. Commands
- `/dkm voice portrait arthas`
- `/dkm voice portrait bolvar`
- Confirm an invalid value prints usage guidance and does not break settings.

## 7. Regression
- Re-test the 3.1.2 Preparation enchant states.
- Re-test Frost dual-wield Main Hand / Off Hand Runeforge guidance.
- Confirm SBA-friendly mode, Gear Mentor, HUDs, presets and voice playback continue to work.
