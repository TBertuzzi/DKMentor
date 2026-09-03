# DK Mentor 3.0.7 — Modal Window Navigation Hotfix

DK Mentor 3.0.7 fixes overlapping configuration windows introduced as the 3.0 UI grew.

## What changed

- **Alert Studio** opened from Mentor Intelligence now temporarily hides the Mentor Intelligence window instead of stacking on top of it.
- **Review 3.0** opened from Mentor Intelligence now does the same.
- Closing Studio or Review automatically restores the exact parent window that launched it.
- Studio → Review is now a true nested modal flow: Review closes back to Studio, and Studio can then close back to Mentor Intelligence.
- Setup Wizard participates in the same return flow when opened from Mentor Intelligence or Alert Studio.
- Setup → Alert Studio → Setup remains supported without losing the original caller.
- Studio and Review are explicitly top-level `FULLSCREEN_DIALOG` frames while visible, with deterministic frame levels.
- Direct `/dkm studio`, `/dkm review`, and `/dkm setup` usage remains available; when a compatible DK Mentor parent window is already visible, the child automatically adopts it instead of stacking.

## Unchanged

- Live Mentor logic, pinned Blizzard NEXT card, Review calculations, Patterns, DK Tools, interrupt handling, resource HUD, and SavedVariables behavior are unchanged.
- SavedVariables schema remains 31 and Setup Wizard schema remains 301.

## Compatibility

- World of Warcraft Retail / Midnight 12.1
- Interface: 120100
