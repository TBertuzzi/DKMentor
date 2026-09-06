# DK Mentor 3.2.0 — Live Test Checklist

## 1. Startup
- Install **3.2.0 Test** over 3.1.6 and `/reload`.
- Confirm no Lua warnings/errors and existing settings/HUD positions remain intact.
- Confirm the addon still remains inactive on non-Death-Knight characters.

## 2. Stats & Folio navigation
- Open **DK Codex -> Stats & Folio** or run `/dkm advisor`.
- Confirm Auto / PvE / PvP buttons are visible and clickable.
- Confirm switching Current / Blood / Frost / Unholy does not change the player's real specialization.
- Confirm switching away to Equipment hides the Advisor context buttons.

## 2b. Native menu/submenu icons
- Confirm every left-side DK Codex section button shows a small native WoW icon and the text remains readable in both English and ptBR.
- Switch Blood / Frost / Unholy and confirm the **Builds** icon follows the browsed specialization and the **Rotation** icon changes to a representative ability for that specialization.
- Open **Builds** and confirm Auto / World / Delve / Dungeon / Mythic+ / Raid / PvP buttons show compact icons without clipping localized labels.
- Confirm Standard and SBA-friendly mode buttons show icons without changing selection behavior.
- Open **Equipment** and confirm Overview / Gear / Preparation / Crafting / Sources / Trinkets / Upgrades show compact icons without text overlap.
- Open **Stats & Folio** and confirm Auto / PvE / PvP buttons show native icons.
- Confirm all icons come from the WoW client: the addon folder should contain no new icon artwork.


## 2c. Full Codex layout regression
- Confirm the main DK Mentor window is slightly larger and remains fully clamped on-screen.
- Visit **Stats & Folio**, then switch directly to every Equipment subview: Overview / Gear / Preparation / Crafting / Sources / Trinkets / Upgrades.
- Confirm no Folio rune rows, stat cards, Advisor status chip, or Advisor context buttons remain visible over Equipment content.
- In every Equipment subview, confirm long Portuguese item/source/preparation text wraps inside its own card and increases the card height instead of overlapping the next row.
- Scroll each long page from top to bottom and confirm cards/panels never overlap, status text remains inside its card, and source/footer notes remain readable.
- Switch repeatedly between Equipment, Stats & Folio, Builds, Overview, and back to Equipment to verify visual pools are always cleared.

## 3. Live stat cards
- Confirm Crit, Haste, Mastery, and Versatility show a percentage plus raw rating when readable.
- Confirm percentage, rating and DR status are split into dedicated lines/positions and no stat-card text wraps outside its card.
- Confirm each card shows `NO DR`, `10% DR`, `20% DR`, `30%+ DR`, or `UNKNOWN` without Lua errors.
- Browse a different spec and confirm the UI clearly states that the live stat cards still belong to the active character.
- On Blood, verify Deathbringer/San'layn direction changes when the active Hero Talent is detected; if browsing or detection is unavailable, verify both Hero Talent variants are shown.

## 4. Advisor context
- In **Auto**, enter normal world/instance content and confirm the displayed context follows the detected environment.
- Pin **PvE** and confirm PvE stat/Folio recommendations remain selected.
- Pin **PvP** and confirm PvP stat/Folio recommendations appear even outside PvP.
- Return to **Auto**.

## 5. Omnium Folio Mentor
- Confirm five Folio recommendation rows appear for Blood, Frost, and Unholy.
- Confirm every Folio row shows the native WoW rune/spell icon on the left; hovering the row should open the native spell tooltip when available.
- Confirm long rune names stay inside the row and never overlap the right-side status badge.
- Confirm `MATCH / REVIEW / FIXED ROW / NOT DETECTED` appears inside a compact status badge instead of floating text.
- With the Folio unlocked, compare the in-game Folio to DK Mentor:
  - recommended selected row -> `MATCH` when detectable;
  - different selectable row -> `REVIEW` when detectable;
  - fixed Lingering row -> `FIXED ROW`;
  - unavailable/secret API state -> `NOT DETECTED` without falsely marking the build wrong.
- Confirm DK Mentor never opens, commits, purchases, or changes a Folio trait.

## 6. Gear Targets 2.0
- Open **Equipment -> Gear** for each spec.
- Confirm existing `EQUIPPED / OWNED / TARGET` cards still work.
- Confirm the new **Catalyst plan** appears after the Season 2 tier panel.
- Validate source order:
  - Blood: Head Nek'zali; Shoulders Temple of Sethraliss; Chest Coiled Altar; Hands King's Rest; Legs Ula'tek.
  - Frost: Head Voidscar Arena; Shoulders Nymrissa Wavecaller; Chest Coiled Altar; Hands Twin Fangs; Legs Ula'tek.
  - Unholy: Head/Shoulders Murder Row; Chest Coiled Altar; Hands King's Rest; Legs Ula'tek.
- Confirm the gear footer shows CURRENT + DK Mentor review date + guide update date.

## 7. Smart item tooltips
- Hover a tracked target in bags/chat/Dungeon Journal/equipment where available.
- Confirm a single **DK Mentor • Gear Target** block is appended.
- Confirm it shows EQUIPPED / OWNED / MISSING and the relevant DK specs/priority/source.
- Hover an unrelated item and confirm DK Mentor adds nothing.
- Re-hover/reuse tooltips and confirm the DK block is not duplicated.

## 8. Build freshness
- Open Builds for Blood and confirm source footer shows **CURRENT**.
- Open Frost/Unholy build profiles and confirm the re-reviewed source footers show **CURRENT**.
- In Frost Mythic+, confirm the guidance mentions Smothering Offense and does not recommend Frostbane.
- In Frost Preparation, confirm Potion of Recklessness is recommended; Light's Potential is alternative; Shattering Blade uses Razorice MH + Fallen Crusader OH; other dual-wield builds use Stoneskin MH + Fallen Crusader OH; two-hand accepts only Fallen Crusader.
- Confirm no build/talent string was changed automatically.

## 9. Localization
- Check English and ptBR if possible.
- Confirm Stats & Folio, statuses, stat labels, Catalyst plan, context buttons, and tooltip labels are localized.
- Native WoW spell/item/rune names should remain in the client language.

## 10. Regression
- DK Pronto hides in combat and returns afterward.
- Lich King portrait remains correctly locked/movable and helper text stays hidden while locked.
- Portrait position survives preview, real commentary, scale changes and `/reload`.
- Preparation / Ready Check remains functional.
- DKM31 export/import remains functional.
- SBA-friendly Build Mentor remains functional.
- Loadout Pilot handoff remains functional.

