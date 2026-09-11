
## 3.3.0 Test r10 - Build source audit (2026-09-09)

- Re-audited Blood, Frost and Unholy PvE build profiles by context against current Wowhead guidance.
- Removed the generic per-spec tree-marker assignment that caused Delve/Open World comparisons to inherit Raid/Mythic+ markers.
- Added context-specific, derived and Hero-only coverage modes.
- Frost Delves now validates Deathbringer only until an exact current Delve import is embedded.
- Unholy Raid/Open World no longer reuse Mythic+ AoE markers.
- Renamed `Create in WoW` to `Clone in WoW` so the UI accurately describes the current behavior.
- Build data reviewed date: 2026-09-09.

# DK Mentor 3.3.0 - Validation Report (Test r9)

Status: **PASS - ready for in-game testing**

## Automated validation

- `scripts/validate.py`: PASS
- Lua syntax (`texluac -p`): 21/21 runtime Lua files PASS
- Smoke tests (`texlua`): 35/35 PASS
- Retail Interface: `120100`
- Addon Version: `3.3.0`

## r9 - Visible guide-key diagnostics

The r8 live-client screenshot reported `4/5 found - 4 selected`. That combination means all four successfully mapped guide keys are selected and **one guide key could not be resolved by DK Mentor**. It does not prove that the player chose a wrong talent.

r9 makes that distinction visible:

- Every guide key now has an individual state: **OK**, **MISSING**, **SWAP**, or **NOT MAPPED**.
- The diagnostic line displays the localized talent name next to that state. Names are display-only; matching remains based on stable node/entry/spell/subtree IDs.
- **NOT MAPPED** explicitly means a DK Mentor guide-data mapping gap.
- **Create in WoW** now explains the exact blocker in its tooltip instead of showing only a disabled button.
- The tree header gained dedicated space for the diagnostic summary and a shorter title to reduce visual crowding.

## Matching safety

The r8 stable-ID logic is unchanged: normal guide keys resolve through node/entry/spell IDs and override/base aliases; Hero Talents resolve through `subTreeID`. r9 does not reintroduce English/PT-BR name matching.

## Expected runtime diff versus Test r8

- `TalentTree.lua`
- `Localization.lua`

No changes to Meta/Archon, GearData, Builds data, Valeera, Preparation, HUDs, or gameplay mentoring.

## Live-client validation still required

1. Open the same Frost Mythic+ loadout that showed 4/5 in r8.
2. Capture which named key is shown as NOT MAPPED.
3. Use that exact key to correct the remaining live 12.1 ID mapping in the next revision if required.
4. Confirm the disabled Create in WoW tooltip names the same blocker.
