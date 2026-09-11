# DK Mentor 3.0.10 — Live Test Checklist

Offline validation cannot reproduce WoW item-cache behavior, protected combat values, UI scale, or Rune cooldown presentation. Test this build in a Retail 12.1.0 client before publishing.

## 1. Upgrade / startup

- Install the 3.0.10 Test package over 3.0.9.
- `/reload`.
- Confirm no Lua errors on login.
- Confirm existing HUD positions/settings remain intact.

## 2. DK Codex — Gear Mentor

Open `DK Codex -> Gear Mentor` or use `/dkm gearmentor`.

### Dashboard

- Correct specialization is shown when browsing Current.
- Equipped item level is readable.
- Runeforge state does not error.
- Enchant/socket diagnostics render without square/missing glyphs.
- Headline target progress is shown.
- Frost shows Dual-wield/Single weapon status without Lua errors.
- Next target is readable and includes slot/source/reason.

### Targets

- Blood, Frost, and Unholy each show their own targets.
- Items already equipped show `EQUIPPED`.
- Items available to the character/account when readable show `OWNED`.
- Missing items show `TARGET`.
- Item names localize through the WoW client when cached.
- Long source/reason text wraps without overlapping UI.

### Sources

- Targets are grouped by source.
- Each line shows status, item, and slot.
- The view remains readable in ptBR and English.

### Trinkets

- The current spec has a short trinket plan.
- Headline trinkets show current ownership state.

### Upgrade Plan

- Crafting and Crest guidance is present.
- The simulation disclaimer remains visible.

## 3. Builds

Open `DK Codex -> Builds` for all three specs/contexts that are practical to browse.

- Hero Talent direction appears when available.
- Focus appears.
- When-to-use explanation appears.
- Patch review date/source appear.
- No talent loadout is created/switched/imported.

## 4. Ordered Rune HUD

Test both Classic and DK Arcs resource styles if possible.

- With 6 ready Runes, all six appear ready.
- Spend one Rune: visually, the depleted Rune should appear on the **right**.
- Spend several Runes: ready Runes should remain grouped on the **left**.
- During regeneration, the Rune closest to completing should be the leftmost depleted Rune.
- As Runes finish, the depleted group should refill visually from **left to right**.
- No Rune mechanics are altered; this is only display ordering.
- Preview still shows a stable ready-to-recharging left-to-right sample.

## 5. Regression checks

- Mind Freeze HUD still appears on a valid interruptible cast.
- Optional Mind Freeze action glow still targets the correct action button/macro.
- Interrupt sound remains OFF by default and does not repeat for one cast.
- Live Mentor first card still follows Blizzard Assisted Combat when enabled.
- Review / Studio modal navigation remains clean.
- Review contains no square/missing glyphs.
- Frost action-bar coverage does not request Soul Reaper.
- Aura HUDs remain active-only outside Preview.
- Resource Arcs remain click-through during normal play.

## Acceptance

Publish 3.0.10 only after the Gear Mentor views are readable at the user's normal UI scale and Rune ordering looks stable during real combat.
