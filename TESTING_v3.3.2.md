# DK Mentor 3.3.2 - Live Test Checklist

## Version / load

1. Confirm the AddOns list reports **DK Mentor 3.3.2**.
2. Confirm Retail Interface **120100** loads without Lua errors.
3. Open `/dkm` and switch between Blood, Frost, and Unholy planning views.

## Build Mentor freshness

1. Blood PvE cards show **REVIEW PENDING** and the source date **2026-09-21**.
2. Frost PvE cards show **REVIEW PENDING** and keep the existing Deathbringer/Rider profiles.
3. Unholy PvE cards show **REVIEW PENDING**.
4. Unholy Raid contains two profiles:
   - Rider — RECOMMENDED / provisional guide baseline.
   - San'layn Blightfall — ALTERNATIVE / post-hotfix review candidate.
5. The San'layn Blightfall profile shows the Blightfall icon/tooltip when the client resolves spell 1242616.
6. Unholy PvP shows REVIEW PENDING while preserving Pet/Rider Recommended and Disease/San'layn Alternative.

## Talent Tree regression

1. Frost Mythic+ still validates the four known context markers.
2. Frost Delves remains Hero-only rather than reusing Raid/Mythic+ markers.
3. Unholy Raid remains Hero-only for tree comparison even with the new San'layn profile; DK Mentor must not claim an exact post-tuning Wowhead import.
4. Saved / Export / Clone in WoW behavior is unchanged.

## Advisor / Gear / Preparation

1. Stats & Folio loads for all specs without missing panels.
2. Gear Mentor reports reviewed **2026-09-24** and keeps the existing item/trinket/crafting/tier targets.
3. Preparation reports reviewed **2026-09-24** and preserves the current consumable/runeforge recommendations.
4. No REVIEW PENDING state is introduced for gear solely because class tuning changed.

## Valeera

1. Open `/dkm valeera`.
2. Confirm the September 23 **Faction-change recovery fixed** entry is visible.
3. Confirm Nemesis / Azta'rec still recommends Healer + Corrosive Bilespear + Soul-Cracking Dreamcatcher + Phantasmal Spore Toxin for Blood/Frost/Unholy.
4. Confirm High Tier and Nemesis remain separate presets.

## Localization

1. Switch DK Mentor to PT-BR and verify the new tuning notes, REVIEW PENDING labels, San'layn Blightfall profile, and Valeera hotfix do not fall back to raw English unexpectedly.
2. Switch back to English and verify no stale localized text remains.

## Regression smoke

- HUDs, Survival Coach, interrupt handling, Lich King commentary, Meta Pulse, Character Check, and Loadout Pilot handoff should behave exactly as in 3.3.1.
