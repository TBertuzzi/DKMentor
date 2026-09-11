# DK Mentor 3.0.12 — Live Test Checklist

Test in Retail 12.1.0 before publishing.

## 1. Upgrade

- Install 3.0.12 Test over 3.0.11.
- `/reload`.
- Confirm no Lua errors and existing settings/positions remain intact.

## 2. Gear Mentor Overview

Open `DK Codex -> Gear Mentor -> Overview`.

- The old `Setup / X to review` metric is gone.
- The fourth metric is `Season 2 Set` and shows `X / 5`.
- A `Season 2 tier set` section appears below the metrics.
- The set name resolves to Baleful Grave-Knight's Crucible (localized by the client when available).
- Five tier slots appear: Head, Shoulders, Chest, Hands, Legs.
- Equipped tier pieces show `EQUIPPED` and the progress count updates.
- 2-piece becomes ACTIVE at 2 equipped set pieces.
- 4-piece becomes ACTIVE at 4 equipped set pieces.
- Hovering either bonus card shows the specialization-specific bonus summary.

## 3. Tier item tooltips

- Hover each tier piece card.
- The native WoW item tooltip appears.
- If the equipped slot is a recognized Season 2 set piece, its equipped hyperlink can be used for the tooltip.
- Move the pointer completely away from the card: the tooltip must disappear immediately.
- Move quickly between multiple item/tier cards and then out of the window: no tooltip should remain stuck.
- Close or switch away from Gear Mentor while a tooltip is visible: the tooltip must close.

## 4. Gear view

Open `Gear`.

- Recommended target cards remain unchanged functionally.
- The five-piece Season 2 tier strip appears below the headline targets.
- Tier progress matches Overview.

## 5. Readability

Open `Trinkets` and `Upgrades`.

- Guidance text is clearly readable and no longer looks disabled.
- Crafting/Crest body text has visibly stronger contrast.
- The source disclaimer is readable without looking like a disabled control.
- The top helper text is not truncated at the normal UI scale.

## 6. Regression

- Sources view still groups target items correctly.
- Recommended item cards still show EQUIPPED / OWNED / TARGET.
- Item-quality colors/icons still load.
- Stat direction remains readable.
- Ordered Rune HUD, Mind Freeze, Live Mentor, Review, DK Tools, Setup Wizard and Alert Studio remain unchanged.

## Acceptance

Publish only after the tooltip-sticking issue is gone in the live client and the tier set strip fits cleanly at the user's normal UI scale.
