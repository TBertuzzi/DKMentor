# DK Mentor 3.0.16 — Visual crafting and no-truncation polish

DK Mentor 3.0.16 completes the Gear Mentor UI pass requested after live testing.

## What changed

### Visual crafted gear
The Crafting tab is no longer a wall of text. It now shows real crafted-item cards with:
- WoW item icons
- item-quality borders
- equipped / owned / craft state
- slot and priority
- recommended embellishment
- native WoW item tooltip on hover
- DK Mentor context in the tooltip explaining when the craft is useful

The crafted fallback targets are specialization-specific for Blood, Frost and Unholy.

### Text clipping removed
Gear Mentor no longer intentionally shortens guidance with `...` in the visual pages. Trinket guidance and upgrade guidance now wrap and grow vertically, while item cards allow names and status details to wrap.

### Cleaner upgrade page
Because Crafting now has its own visual tab, the Upgrades tab focuses on Crests and upgrade priorities instead of repeating the crafting text again.

### Portuguese cleanup
Filled missing ptBR strings that could leak English UI text, including the Upgrade Plan title and Frost crafting guidance. Proper item/embellishment names are still resolved from the WoW client when available.

### Codex navigation
The left menu keeps the full section name in the page title but uses shorter localized menu labels such as Equipment / Equipamento and Verification / Verificação, avoiding clipped buttons. Specialization icons from 3.0.15 remain, including the live active-spec icon on Current.

## Version
- DK Mentor: **3.0.16**
- Retail interface: **120100**
