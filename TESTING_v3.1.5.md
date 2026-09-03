# DK Mentor 3.1.5 — Live Test Checklist

## 1. Startup
- Install **3.1.5 Test** over 3.1.4 and `/reload`.
- Confirm there are no Lua warnings/errors.
- Confirm existing SavedVariables, HUD positions and selected portrait character remain intact.

## 2. Voice / portrait synchronization
- Enable the portrait and keep it **locked**.
- Test **Arthas** with several Preview Voice lines of different lengths.
- Confirm the talking animation begins with playback and stops when the audible voice ends.
- Confirm the portrait disappears almost immediately after the voice ends; it should no longer remain for the former ~10-second busy window.
- Repeat with **Bolvar** selected.
- Unlock the portrait and confirm preview mode remains visible for positioning even when no voice is playing.

## 3. Compact main window
- Open DK Mentor and confirm the main frame is visibly shorter/smaller than 3.1.4.
- Check **Combat**, **DK Codex**, and **Settings** tabs.
- In Settings, confirm HUDs and Layout, Loadout automation, and Lich King commentary all fit without overlapping the footer.
- Confirm every Lich King row control remains clickable: Situations, Voice mapping, Preview, Frequency, Portrait, Lock, Scale, Character.
- Open DK Codex Gear / Preparation and scroll to the bottom; no content should be lost because of the reduced frame height.

## 4. Regression
- Open Layout Presets and confirm it still renders above the main window and remains draggable.
- Export/import a DKM31 preset.
- Re-test Preparation enchant states.
- Re-test Frost dual-wield Main Hand / Off Hand Runeforge cards.
