# DK Mentor 1.1.4

- Fixes the immediate `/reload` error from 1.1.3 caused by the Classic resource HUD calling `CenterResourceArcHUD` before that local helper was declared.
- Classic DK Resources once again restores its saved position normally.
- DK Arcs remains non-movable and auto-centered.
- Health color still switches to red at 30% HP or less, even if numeric text is disabled.
