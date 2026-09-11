# DK Mentor 3.1.1 — Live Test Checklist

Install **3.1.1 Test** over the failed 3.1.0 test build.

## Startup
- Log in or `/reload` and confirm DK Mentor loads with no `more than 200 local variables` warning.
- Confirm the main window, status widget, combat HUDs and minimap button initialize.

## 3.1 regression
- Open **DK Codex → Gear Mentor → Preparation** and verify cards/tooltips render.
- Switch **Standard / SBA-friendly** in Build Mentor.
- Open `/dkm preset`, export the current layout, then import it out of combat.
- Enable the optional Lich King portrait, unlock/move/lock it, preview commentary, and confirm the portrait hides after playback.
- Verify EN and pt-BR labels.

## Combat regression
- Verify Rune/Runic Power HUD, buffs/debuffs/ability bars and Mind Freeze alert still work.
- Confirm no Lua errors during combat entry/exit.

## Acceptance
3.1.1 is ready for publication only after the live client loads cleanly and the four 3.1 features above pass.
