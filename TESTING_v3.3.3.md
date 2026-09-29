# DK Mentor 3.3.3 Test r1 - Live Testing Checklist

## Install / startup

- Install the Test r1 ZIP over a clean or existing 3.3.2 DK Mentor installation.
- Confirm the AddOns list shows **DK Mentor 3.3.3**.
- Log in on a Retail Death Knight and confirm there are no Lua errors.
- Open `/dkm` and move through the Codex sections once.

## Unholy Build Mentor

### Open World
- Confirm Rider of the Apocalypse is first and **RECOMMENDED**.
- Confirm the source/freshness presentation is readable.

### Delve
- Confirm San'layn Blightfall is first and **RECOMMENDED**.
- Confirm Rider is **ALTERNATIVE**.
- Confirm Blightfall appears among the San'layn key talents/markers.

### Dungeon / Mythic+
- Confirm San'layn Blightfall is first and **RECOMMENDED**.
- Confirm Rider remains **ALTERNATIVE**.
- Confirm the Rider profile still documents the 3+ target Epidemic threshold.
- Confirm switching between both Hero Talent profiles does not break the Visual Talent Tree.

### Raid
- Confirm San'layn Blightfall is first and **RECOMMENDED**.
- Confirm Rider is **ALTERNATIVE**.
- Confirm the Raid tree coverage is clearly Hero-only/partial rather than claiming an exact full imported guide tree.

## Unholy guide

- Open the Unholy guide and confirm the **San'layn / Blightfall timing** section renders without clipping.
- Verify Dark Transformation, Soul Reaper, Blightfall, Putrefy, and Lesser Ghoul wording is readable in EN and pt-BR.

## Unholy PvP regression

- Confirm Pet/Rider remains provisional **RECOMMENDED**.
- Confirm Disease/San'layn remains **ALTERNATIVE**.
- Confirm both are still **REVIEW PENDING**.

## Cross-spec regressions

- Blood PvE remains REVIEW PENDING.
- Frost PvE remains REVIEW PENDING.
- Frost Mythic+ still exposes the existing Frostscythe 2+ / Glacial Advance 3+ markers.
- Valeera Nemesis/Azta'rec remains Healer + Corrosive Bilespear + Soul-Cracking Dreamcatcher + Phantasmal Spore Toxin.
- Gear Mentor, Preparation, Stats/Folio, Meta Pulse, HUDs, Survival Coach, Talent Tree saved/clone behavior, and Lich King commentary open normally.

## Pass criteria

Test r1 is ready for release when all recommendation order/badges render correctly, no old provisional Unholy PvE wording remains visible in active profiles, pt-BR/EN layouts do not clip, and no Lua/runtime regression appears.
