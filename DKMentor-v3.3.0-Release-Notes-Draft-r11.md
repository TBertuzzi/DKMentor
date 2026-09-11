# DK Mentor 3.3.0 - Release Notes Draft (Test r11)

## Talent-tree button consistency

The talent-tree action area now uses DK Mentor's own flat dark/cyan button system instead of Blizzard's red `UIPanelButtonTemplate` skin.

- Salvos / Saved
- Salvar / Save
- Exportar / Export
- Clonar no WoW / Clone in WoW
- Abrir Talentos / Open Talents

Button widths are calculated from the localized rendered text, so longer pt-BR labels no longer get squeezed into fixed widths. The action row keeps consistent height/spacing and the tree title automatically uses the space left over.

The same styling was also applied to the Export/Saved subpanel actions so the red Blizzard buttons do not return when those panels are opened.

This revision does not alter the r10 source-audit decisions, context-specific build markers, talent matching, or clone/export/save behavior.
