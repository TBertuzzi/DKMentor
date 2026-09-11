
## 3.3.0 Test r10 - Build source audit (2026-09-09)

- Re-audited Blood, Frost and Unholy PvE build profiles by context against current Wowhead guidance.
- Removed the generic per-spec tree-marker assignment that caused Delve/Open World comparisons to inherit Raid/Mythic+ markers.
- Added context-specific, derived and Hero-only coverage modes.
- Frost Delves now validates Deathbringer only until an exact current Delve import is embedded.
- Unholy Raid/Open World no longer reuse Mythic+ AoE markers.
- Renamed `Create in WoW` to `Clone in WoW` so the UI accurately describes the current behavior.
- Build data reviewed date: 2026-09-09.

# DK Mentor 3.3.0 - Test r9 Checklist

## 1. Install

1. Replace the existing `DKMentor` folder with the r9 test folder.
2. Run `/reload`.
3. Confirm version `3.3.0`.

## 2. Guide-key diagnostics

1. Open `/dkm builds`.
2. Select **Frost / Gelido** and **Mythic+** using the same loadout that showed `4/5 found - 4 selected` in r8.
3. Scroll to the talent-tree panel.
4. Confirm the status line shows mapped and selected counts separately.
5. Confirm the new colored diagnostic line names every guide key individually.
6. If the live client still reports 4/5, verify that one item is explicitly labeled **NOT MAPPED / NAO MAPEADO**.
7. Important: `NOT MAPPED` means DK Mentor could not resolve the guide ID against the live Blizzard tree; it does **not** claim the player's talent is wrong.
8. If a mapped guide node is not selected, verify it is labeled **MISSING / FALTANDO**.
9. If a mapped choice node selects the other entry, verify it is labeled **SWAP / TROCAR**.

## 3. Create in WoW blocker

1. Hover **Create in WoW / Criar no WoW** while it is disabled.
2. Confirm the tooltip names the exact blocker.
3. For an unmapped node, confirm the tooltip explicitly identifies it as a DK Mentor guide-data mapping issue.
4. Confirm the button only enables when all guide keys are mapped and selected, the current specialization is active, and the player is out of combat.

## 4. Tree readability

1. Confirm the short title `Talent tree - guide check` / localized equivalent fits without colliding with action buttons.
2. Confirm the diagnostic line remains visible above the tree, so the player does not have to inspect the graph to discover the missing key.
3. Confirm Class/Hero/Spec spacing and Hero vertical alignment from r6/r7 remain intact.
4. Scroll the Codex and verify the full tree remains reachable; the diagnostic summary must remain above the graph.

## 5. Regression

- Export / Save / Saved remain functional.
- Direct Blizzard loadout creation logic from r8 is unchanged.
- `/dkm meta` and Archon status unchanged.
- PT-BR Guide vs Logs remains ID-based.
- Gear Mentor / Unholy 3.2.1 targets unchanged.
- Valeera, Preparation, HUDs and Lich King commentary unchanged.
- Distinct Codex sidebar icons remain intact.

## 6. Safety

DK Mentor still does not purchase/refund individual talent points or silently edit the active build. A guide key that cannot be mapped blocks direct creation and is now identified explicitly instead of being presented as an unexplained count mismatch.
