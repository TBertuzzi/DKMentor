# DK Mentor v3.2.0 – Testing Notes (r7)

## Focus of this revision
Two areas requested during 3.2 testing:

1. Re-review Frost Season 2 weapon / Runeforge guidance.
2. Replace the unreliable **Open Folio** shortcut with an in-addon Omnium Folio editor.

## Frost weapon guidance changes
- Corrected the practical dual-wield slot assignment after Blizzard's August 20 hotfix:
  - **Main Hand:** Aman'muso, Warlord's Vengeance
  - **Off Hand:** Jaw of the Shackled Goddess
- Aman'muso is Main Hand-only, so the old r4 slot presentation could not be used literally.
- Season 2 PvE continues to favor dual-wield as the default gearing direction.
- Frost Runeforge guidance now distinguishes:
  - Dual-wield Shattering Blade / Frostbane: Razorice main hand + Fallen Crusader off hand.
  - Dual-wield Breath-style setup without weapon Razorice: Stoneskin Gargoyle main hand + Fallen Crusader off hand.
  - Standard 2H: Fallen Crusader.
  - 2H Breathbane: Razorice is shown as a supported alternative instead of being flagged as wrong.

## Omnium Folio quick editor
The Stats & Folio page now includes a compact visual editor inspired by the native Folio presentation:
- Five rune slots are shown in one compact row.
- Clicking an editable slot cycles through the choices exposed by the live Omnium Folio trait node.
- The editor discovers the current choices dynamically from `C_Traits` / tree 1186, so it is not limited to only the rune names hardcoded in DK Mentor.
- **Recommended** resets the draft to DK Mentor's recommendation for the selected PvE/PvP context.
- **Apply Folio** stages and commits the selected rows through the generic trait API.
- The addon never changes Folio choices automatically.
- Changes are blocked in combat.
- If the Blizzard Folio already has unrelated staged changes, DK Mentor refuses to commit over them.
- If a choice is locked/unavailable and staging fails, the staged DK Mentor changes are rolled back.

## In-game test checklist
### Frost weapon guidance
1. Open **Codex > Equipment** as Frost.
2. Confirm the headline weapon pair is shown as Aman'muso MH + Jaw OH.
3. With dual-wield + Shattering Blade, verify Ready Check expects Razorice MH + Fallen Crusader OH.
4. With a non-Shattering dual-wield setup, verify Stoneskin Gargoyle MH + Fallen Crusader OH guidance.
5. With 2H, verify Fallen Crusader and the Breathbane Razorice alternative are presented without a false failure.

### Folio editor
1. Open **Codex > Stats & Folio**.
2. Confirm the compact five-slot editor appears above the detailed Folio rows.
3. Hover each slot and confirm native spell tooltip plus DK Mentor help text.
4. Click rows 1/2/4/5 and verify the icon cycles through the live choices for that row.
5. Row 3 should remain fixed when the live tree exposes only the fixed choice.
6. Click **Recommended** and confirm the five draft slots return to the current DK Mentor context recommendation.
7. Click **Apply Folio** outside combat and confirm the Blizzard Omnium Folio actually changes.
8. Enter combat and confirm Apply is blocked.
9. After applying, reopen/refresh the page and confirm detailed rows show MATCH/CORRETO for matching recommendations.

## Important
The Folio write path is now intentionally user-driven. DK Mentor will not silently change runes on login, specialization change, context change, or combat state.
