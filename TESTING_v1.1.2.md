# DK Mentor 1.1.2 live-client test checklist

## DK Arcs visual

- Set DK Resources style to **DK Arcs**.
- Enable **Preview HUDs** outside combat.
- Confirm two visible curved bars appear around the character: green Health on the left and blue Runic Power on the right.
- Confirm six DK rune glyphs appear centered below the character.
- Lock HUDs and confirm the editing handle disappears while the arcs remain visible.

## Runtime

- Take damage and verify the left Health arc decreases from top to bottom.
- Generate/spend Runic Power and verify the right arc fills/empties.
- Spend multiple Runes and verify the six rune glyphs refill independently.
- Swap Blood/Frost/Unholy and verify rune accent color changes red/blue/green.

## Regression

- Classic resource style still works.
- Preview overrides combat-only visibility.
- Bars only in combat still hides the HUD after combat.
- HUD lock affects movement only.
- No Lua errors on `/reload`, combat entry/exit, spec swap, death/resurrection, or zone changes.
