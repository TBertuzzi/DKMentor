# DK Mentor 1.1.6

This is a focused hotfix for the DK Arcs Health warning.

- At **30% HP or lower**, the Health arc and percentage text turn red.
- Above 30%, the Health arc stays green.
- Uses the existing `GetPlayerHealthPercent()` compatibility helper so the threshold can work when raw health values are protected in Midnight combat.
- No changes to arc spacing, movement, Runic Power, Runes, size, or opacity.
