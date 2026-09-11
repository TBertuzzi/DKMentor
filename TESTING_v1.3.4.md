# DK Mentor 1.3.4 live test checklist

1. Start out of combat on Frost with `Frost / Raid` mapped to `DKM Raid`.
2. Paste a different valid Frost import string and click **Save code**.
3. Confirm the code remains in DK Mentor after changing tabs/reopening the window.
4. Open the native WoW Talents UI and confirm `DKM Raid` now contains the newly imported talents rather than the old version.
5. Confirm DK Mentor still reports `Associated: DKM loadout: DKM Raid` and does not leave a second stale `DKM Raid` after the async import settles.
6. While configuring Raid from World, confirm DK Mentor restores the loadout that was selected before the update when appropriate.
7. Repeat with a player-named mapped loadout (not `DKM Raid`) and confirm **Save code does not overwrite it**.
8. Try a code from the wrong DK specialization; confirm the code is stored locally but the WoW loadout is unchanged and a clear message is shown.
9. Try while in combat; confirm only the local code is saved.
10. Regression: open Dungeon Overrides, DK Codex, aura HUDs, right-click Build HUD, and change contexts to ensure 1.3.3/1.3.2/1.2.x behavior remains intact.
