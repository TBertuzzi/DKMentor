# DK Mentor 2.0.3 - Live Test Checklist

## Arc HUD click-through

- [ ] Lock HUDs, place an enemy between the Health and Runic Power arcs, and confirm the enemy can be clicked normally.
- [ ] Confirm clicking through the empty center area targets/interacts with the world rather than the DK Mentor frame.
- [ ] Leave HUDs unlocked, enter combat, and confirm the arc HUD still becomes click-through immediately.
- [ ] Exit combat and confirm the small **Drag to move** handle returns while HUDs remain unlocked.

## Arc positioning

- [ ] Out of combat, unlock HUDs and confirm the small drag handle is visible.
- [ ] Drag the handle and confirm the entire Health / Runic Power / Rune HUD moves together.
- [ ] Lock HUDs and confirm the drag handle disappears.
- [ ] Reload UI and confirm the saved arc position is preserved.

## Regression

- [ ] Health arc, Runic Power arc, percentages, and all six Rune icons still update normally.
- [ ] Arc spacing / scale / opacity settings still work.
- [ ] Empty DK Buffs / External Buffs / Debuffs still leave no black panel in normal play.
- [ ] No `Button:HookScript()` secret-aspect error appears.
- [ ] No automatic specialization, talent, equipment, or Loot Specialization changes occur.
