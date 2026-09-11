# DK Mentor 3.0.12 — Tier Set & Gear Mentor Polish

DK Mentor 3.0.12 refines the visual Gear Mentor introduced in 3.0.11 after live-client testing.

## Season 2 tier set is now visual

The Overview now replaces the ambiguous `Setup` counter with **Season 2 Set** progress and adds a dedicated visual section for **Baleful Grave-Knight's Crucible**.

The panel shows all five Death Knight tier slots:

- Head
- Shoulders
- Chest
- Hands
- Legs

Each slot has a real item icon, `EQUIPPED` / `OWNED` / `TARGET` state, and native WoW item tooltip. The panel also shows live equipped progress and the current **2-piece / 4-piece** activation state for Blood, Frost, or Unholy.

Equipped tier detection uses the live item-set ID when item data is available, which is more appropriate for catalyzed/equipped Season 2 tier pieces than checking only a single canonical item ID.

The Gear view also includes the compact five-piece tier strip so the seasonal set remains visible outside Overview.

## Tooltip lifecycle fix

Item tooltips could remain visible after the pointer left a Gear Mentor card. 3.0.12 keeps the normal `OnLeave` cleanup and adds an ownership-aware hover fallback while the Gear Mentor is open. Tooltips are also cleared when cards or the visual Gear Mentor hide.

## Readability pass

Raised text contrast across:

- metric labels;
- item metadata;
- trinket guidance;
- crafting / Crest guidance;
- source disclaimer;
- current-stat snapshot;
- the top hover hint.

The hover hint is shorter to avoid truncation in Portuguese.

## Safety

Gear Mentor remains read-only. It does not equip items, spend Crests, use the Catalyst, apply enchants/gems, buy items, or change talents/loadouts.

## Version

- DK Mentor: **3.0.12**
- World of Warcraft Retail / Midnight: **12.1.0**
- Interface: **120100**
- SavedVariables schema: **31**
