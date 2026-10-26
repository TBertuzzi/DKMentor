# DK Mentor 3.3.4 - Release Notes

Data review date: **2026-10-13**  
Compatibility hotfix review: **2026-10-20**  
Final release review: **2026-10-26**

DK Mentor 3.3.4 updates the published 3.3.3 runtime for World of Warcraft Retail **12.1.5** and incorporates the source changes that materially affect current guidance.


## Interrupt visibility hotfix

Live testing on 12.1.5 found that the Mind Freeze interrupt prompt could stop appearing even though the rest of DK Mentor remained functional. The final 3.3.4 release includes the tested r2 hardening for that path without changing build recommendations or combat automation.

- `UNIT_SPELLCAST_INTERRUPTIBLE` / `UNIT_SPELLCAST_NOT_INTERRUPTIBLE` are registered specifically for `target`; their event name is now the primary readable interruptibility state.
- The central Mind Freeze HUD and the optional action-bar glow both honor that target-scoped event state before falling back to the Secret-safe cast API boolean.
- Mentor Coach no longer assumes `castGUID` or `spellID` are present on interruptibility-event payloads; it resolves the live target cast using `UnitCastingInfo` / `UnitChannelInfo` and the NeverSecret `castBarID`.
- Cast API polling remains as a transition fallback, so short event-order gaps do not suppress the alert.
- No changes to Blood/Frost/Unholy build recommendations, Gear targets, Valeera presets, Talent Tree, Assisted Combat, or layout.

## Retail 12.1.5 compatibility

- Retail Interface updated from **120100** to **120105**.
- Live patch target updated from **12.1.0** to **12.1.5**.
- Remaining legacy item API fallbacks removed from DK Mentor runtime.
- Gear/Advisor item lookups now use the current `C_Item` API paths, including item info, item icons, item quality colors, counts and item spells.
- Existing Assisted Combat, Talent Tree, HUD, Survival Coach, Meta Pulse and loadout-boundary behavior is intentionally unchanged.

## Valeera Delve guidance refresh

The current general Valeera guide now recommends the same Curio pair for all three roles:

- **Combat Curio:** Corrosive Bilespear
- **Utility Curio:** Dundun's Favor

DK Mentor therefore changes its normal Auto, Safe, Balanced, Fast, High Tier and Leveling presets to **Corrosive Bilespear + Dundun's Favor** for Blood, Frost and Unholy.

The boss-specific **Nemesis / Azta'rec** preset is intentionally unchanged:

- Healer Valeera
- Corrosive Bilespear
- Soul-Cracking Dreamcatcher
- Phantasmal Spore Toxin
- Soulthirst Venom remains the documented poison alternative

The current Azta'rec guide still recommends Dreamcatcher for that encounter, so DK Mentor does not incorrectly replace the boss-specific setup with the new general-purpose baseline.

## Unholy / Blightfall tuning wording

Blizzard's October 6 tuning changed **Blightfall** to deal **100% of the remaining plague damage**, down from the temporary 200% value after the earlier bug fix.

- DK Mentor keeps the current San'layn / Blightfall PvE direction from 3.3.3.
- The in-addon timing explanation now reflects the current **100% remaining plague damage** value.
- No artificial new target-count or timing threshold was invented.

## Labyrinth of Kindo'jan

Patch 12.1.5 introduces the Labyrinth, a new mega-Delve experience that uses Valeera.

DK Mentor keeps its existing `C_PartyInfo.IsDelveInProgress()` path as the primary Delve detector. No undocumented map-ID workaround is included. DK Mentor continues to rely on Blizzard's native Delve detector so Labyrinth guidance follows the client's own classification.

## Gear Mentor review state

Patch 12.1.5 adds new mid-season/Kith'ix loot and current guide pages have begun incorporating those items. This compatibility build does **not** silently replace DK Mentor's full gear target lists without a dedicated item audit.

- Blood, Frost and Unholy **Gear freshness is marked REVIEW**.
- Existing gear targets remain visible rather than being removed prematurely.
- A focused 12.1.5 gear refresh can follow once current live targets are fully reconciled.

## Compatibility

- Addon Version: **3.3.4**
- Retail Interface: **120105**
- Live Patch target: **12.1.5**
- Data review date: **2026-10-13**


## Final release review

A final source/hotfix review on **2026-10-26** found no newer Death Knight hotfix requiring runtime or build-guidance changes after the tested r2. The final CurseForge archive therefore promotes the exact tested r2 runtime without code changes.
