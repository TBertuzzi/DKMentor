# DK Mentor 3.1.4 — Live Test Checklist

## 1. Startup
- Install **3.1.4 Test** over 3.1.3 and `/reload`.
- Confirm there are no Lua warnings/errors.

## 2. Layout Presets modal
- Open Settings -> Combat HUDs -> Layout presets.
- Confirm the preset window is fully above the main DK Mentor window.
- Confirm its EditBox and all four buttons are clickable.
- Drag the preset window and confirm it moves normally outside combat.
- Close it with the X and reopen it.

## 3. Portrait settings layout
- Open Settings -> Lich King commentary.
- Confirm Portrait ON/OFF, Portrait LOCKED/UNLOCKED, Portrait scale and Portrait character are all on one row and do not overlap the footer or neighboring sections.
- Check both ptBR and enUS if possible.

## 4. Bolvar Lich King model
- Select **Bolvar**.
- Unlock/show the portrait.
- Confirm the model is Bolvar in his **Lich King / Helm of Domination** form, not normal or unhelmed Bolvar.
- Preview commentary and confirm the talking-animation behavior still works/falls back safely.

## 5. Regression
- Switch back to Arthas and confirm his model still works.
- Export/import a DKM31 preset with Bolvar selected and confirm the character is restored.
- Re-test Preparation enchant status and Frost dual-wield Main Hand / Off Hand Runeforge cards.
