# Testing DK Mentor 1.1.8

1. Open **Settings** and confirm the language button shows the current choice.
2. Open the picker and confirm **Automatic (WoW)**, **Português (Brasil)**, and **English** are available.
3. Choose English from a ptBR WoW client and confirm `/reload` occurs and the DK Mentor UI opens in English.
4. Choose Português (Brasil) and confirm the UI returns to Portuguese after reload.
5. Choose Automatic and confirm it follows the WoW client language.
6. Confirm the selected choice persists after logout/login and `/reload`.
7. Test `/dkm language auto`, `/dkm language ptbr`, and `/dkm language en`.
8. While in combat, choose another language and confirm the preference is saved without forcing a protected UI rebuild; after combat use `/reload` and verify the selection.
9. Regression-check DK Arcs, Buffs do DK, abilities, Preview HUDs, and HUD locking after each language change.
