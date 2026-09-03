# DK Mentor 2.0.2 - Live Test Checklist

## Empty managed aura bars

- [ ] Leave **Preview HUDs OFF** and unlock HUDs. With no tracked DK proc active, confirm **DK Buffs** leaves no black panel, title, or `Drag to move` text.
- [ ] With no qualifying external buff, confirm **External Buffs** also leaves no empty panel.
- [ ] With no debuff, confirm **Debuffs** also leaves no empty panel.
- [ ] Gain a tracked DK proc and confirm the Blizzard-managed icon appears normally even while HUDs are unlocked.
- [ ] Let the proc expire and confirm the icon disappears without leaving the empty panel behind.
- [ ] Repeat active -> empty for External Buffs and Debuffs.

## Positioning

- [ ] Turn **Preview HUDs ON** and confirm the aura placeholders/frame/title appear so empty bars can be positioned.
- [ ] Drag each aura HUD, turn Preview OFF, and confirm empty panels disappear again.
- [ ] Reload the UI and confirm saved positions remain intact.

## Regression

- [ ] Confirm the compact DK status widget remains thin with no large trailing gap.
- [ ] Confirm **Selecionar URL da fonte** still fits completely in PT-BR.
- [ ] No `Button:HookScript()` secret-aspect error appears on login, combat, aura changes, or instance transitions.
- [ ] No automatic specialization, talent, equipment, or Loot Specialization changes occur.
