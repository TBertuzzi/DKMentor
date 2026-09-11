# DK Mentor 3.3.0 - Test r11 Checklist

Base: **3.3.0 Test r10**. This revision is a UI consistency pass only; the r10 source/context-marker audit and talent comparison logic are unchanged.

## 1. Talent-tree action buttons

1. Open `/dkm builds` and scroll to the visual talent tree.
2. Confirm the header actions no longer use the red Blizzard `UIPanelButtonTemplate` appearance.
3. Confirm **Salvos**, **Salvar**, **Exportar**, **Clonar no WoW** and **Abrir Talentos** use the same dark/cyan DK Mentor action-button style used elsewhere in the addon.
4. Hover and press each enabled action and confirm the normal DK Mentor hover/pressed states are visible.
5. Disable an action by browsing a non-current specialization or by removing the required loadout context and confirm the disabled state is dark/gray, not red.

## 2. Localized sizing

1. Test in pt-BR at the normal UI scale.
2. Confirm every header button expands to fit its localized text with horizontal padding.
3. `Clonar no WoW` and `Abrir Talentos` must not clip or touch their borders.
4. `Salvos (N)` must resize when the snapshot count changes.
5. The buttons must keep a consistent 28 px height and 6 px spacing.
6. The talent-tree title must stop before the action row instead of overlapping it.

## 3. Snapshot/export panels

1. Open **Exportar** and confirm the panel **Fechar** button also uses DK Mentor styling.
2. Open **Salvos** and confirm **Fechar**, **Copiar**, **Criar**, **Excluir** and **Abrir Talentos** use DK Mentor styling.
3. Confirm the saved-row Create button still reflects enabled/disabled state correctly.

## 4. Regression

- r10 context/source coverage labels remain unchanged.
- `Clonar no WoW` semantics remain unchanged.
- Export, Save, Saved, direct clone, tooltips and combat/spec safeguards remain unchanged.
- Meta/Archon, Gear, Valeera, Preparation, HUDs and Lich King commentary are unchanged.
