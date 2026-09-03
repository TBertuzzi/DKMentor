# DK Mentor 3.0.6 — Pinned Blizzard Next Action

DK Mentor 3.0.6 makes the Live Mentor easier to read during combat by giving the first card a stable job: when enabled and available, it mirrors the next ability recommended by Blizzard Assisted Combat.

## What changed

- Card 1 is pinned to `C_AssistedCombat.GetNextCastSpell(false)` when **Next action** is enabled.
- The card is labeled **NEXT / PRÓXIMA** and identifies Blizzard Assisted Combat as the source.
- Cards 2 and 3 remain available for DK Mentor context: defensives, interrupts, utility, resource pressure, proc reactions, and spec-specific coaching.
- Duplicate spells are suppressed, so the same ability is not repeated in multiple cards.
- If the Blizzard recommendation is unavailable, the existing Mentor behavior is used unchanged.
- The first card has a subtle cyan visual identity; urgent defensive cards keep their stronger warning treatment.
- **Next action** is ON by default and can be changed from Mentor Intelligence or Alert Studio.
- Slash control: `/dkm mentor nextaction on|off`.

## Safety / scope

DK Mentor does not calculate a custom offensive APL. The next-action card is sourced from Blizzard's own Assisted Combat API. DK Mentor never casts abilities or selects targets automatically.

## Compatibility

- World of Warcraft Retail / Midnight 12.1
- Interface: 120100
