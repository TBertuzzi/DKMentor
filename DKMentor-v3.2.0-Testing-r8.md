# DK Mentor v3.2.0 — Testing r8

## Focus: Valeera — Delve Mentor

This test build adds a new **Valeera** section to the DK Codex. It is recommendation-only and does not change Valeera's live role, Curios, or Poison.

### Navigation
1. Open `/dkm` -> **DK Codex** -> **Valeera**, or use `/dkm valeera`.
2. Confirm the left-menu Valeera button has a native WoW Rogue/Stealth icon.
3. Switch Current / Blood / Frost / Unholy and confirm the Valeera recommendation updates without changing the player's real spec.

### Presets
Test all five presets:
- Auto
- Safe
- Balanced
- Fast
- High Tier

Confirm the selected preset is highlighted, persists after closing/reopening the window, and refreshes the four recommendation cards.

### Expected Auto pairings
- **Blood:** Valeera DPS + Corrosive Bilespear + Soul-Cracking Dreamcatcher + Bursting Toad Toxin.
- **Frost:** Valeera Healer + Corrosive Bilespear + Soul-Cracking Dreamcatcher + Frostheart Venom.
- **Unholy:** Valeera Healer + Corrosive Bilespear + Soul-Cracking Dreamcatcher + Bloodcrypt Toxin.

These role pairings are DK Mentor recommendations. The Curio baseline follows the current Season 2 guide direction.

### UI / icons
- Confirm the four top recommendation cards fit without clipping: Role / Combat Curio / Utility Curio / Poison.
- Confirm native WoW icons appear for roles, Curios, and Poisons.
- Hover Curio/Poison cards and confirm the native spell tooltip opens when the client exposes it.
- Role cards should show DK Mentor explanatory tooltips instead of unrelated Rogue spell tooltips.
- Confirm long PT-BR labels remain inside the cards.
- Scroll through Roles, Combat Curios, Utility Curios, and all six Poisons and confirm no overlap.

### Context chip
- Outside a Delve: the page should show **GUIA DK**.
- Inside a Delve: the page should show **DELVE ATIVA** when DK Mentor detects the Delve context.

### Regression
- Switch repeatedly between Valeera -> Stats & Folio -> Equipment -> Builds -> Valeera.
- Confirm no Valeera cards/preset buttons remain visible over other Codex sections.
- Confirm Stats/Folio, Gear Mentor, Builds, Folio editor, Lich King portrait, DK Ready, and existing HUDs still behave normally.
