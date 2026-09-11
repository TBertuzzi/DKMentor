# DK Mentor v3.2.0 — Testing r9

## Focus: Valeera native configuration shortcut

This revision keeps the r8 Valeera Mentor and adds a direct shortcut to Blizzard's own **Delves Companion Configuration** window.

### Valeera button
1. Open `/dkm` -> **DK Codex** -> **Valeera**.
2. Confirm the new **Abrir configuração da Valeera** button appears beside the status chip.
3. Click it out of combat.
4. Confirm Blizzard's native Valeera/Delves companion configuration opens — not the talent tree, Folio, or another Player Spells page.
5. In the Blizzard window, confirm you can reach the live companion controls for role, Combat Curio, Utility Curio, and poison as normally allowed by the game.

### Combat safety
1. Enter combat.
2. Click **Abrir configuração da Valeera**.
3. Confirm DK Mentor blocks the action and does not try to open/configure the companion while in combat.

### Recommendation page regression
- Test Blood / Frost / Unholy.
- Test Auto / Safe / Balanced / Fast / High Tier.
- Confirm the four recommendation cards still fit.
- Confirm the new button does not collide with **DELVE ATIVA / GUIA DK**.
- Switch Valeera -> Stats & Folio -> Equipment -> Builds -> Valeera and verify no UI leakage.

### Important behavior
DK Mentor still does **not** automatically change Valeera. The new button only opens Blizzard's native configuration so the player can apply the recommended setup manually.
