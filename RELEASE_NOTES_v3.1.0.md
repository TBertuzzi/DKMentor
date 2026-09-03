# DK Mentor 3.1.0 — Preparation, Accessibility & Presets

DK Mentor **3.1.0** expands the pre-combat side of the addon while keeping the same read-only, Death Knight-focused philosophy.

## Preparation & Ready Check

Gear Mentor now includes a dedicated **Preparation** view for Blood, Frost, and Unholy. It combines live character checks with current Season 2 recommendations for:

- Runeforge;
- common armor/ring enchants;
- gems and empty sockets;
- flask;
- combat potion;
- healing potion;
- temporary weapon consumable;
- augment rune;
- food.

The page presents recommendation cards with WoW item/spell icons and native tooltips plus a compact readiness score. Consumable readiness checks whether a recommended option is available in bags. Enchant readiness verifies that expected equipment slots have a permanent enchant; the recommendation cards show the current guide choice. Socket readiness identifies empty sockets without pretending the API can always prove the exact gem recommendation.

Frost Runeforge guidance distinguishes **2H** from **Dual Wield** and accounts for **Shattering Blade** when choosing the expected main-hand rune.

DK Mentor never applies an enchant, gem, Runeforge, consumable, or item automatically.

## SBA-friendly Build Mentor

Build Mentor now has **Standard** and **SBA-friendly** views.

The optional SBA-friendly view is intended for players who rely on Blizzard's Single-Button Assistant. It favors lower-friction recommendations where the reviewed guide direction offers a reasonable choice and calls out that defensives, healing decisions, interrupts, crowd control, grips, utility, pet positioning, movement, and situational PvP decisions still remain manual.

This mode does not recreate, control, or bypass Blizzard's assistant. It is recommendation-only.

## Layout preset export/import

DK Mentor layouts can now be shared as a compact **DKM31** text preset.

The preset covers DK Mentor frame positions and relevant visual settings, including the combat HUDs and the optional Lich King portrait. Import is blocked during combat and always relocks movement handles after applying a preset. Presets are parsed as bounded data only; no Lua code is evaluated.

Use **Settings → Layout presets...** or `/dkm preset`.

## Optional Lich King commentary portrait

The optional Lich King commentary can now display a small movable portrait while a commentary line is playing.

- Disabled by default.
- Can be enabled, unlocked/moved, relocked, and scaled.
- Position/scale are saved and included in DK Mentor layout presets.
- Uses WoW-native model/icon resources when available.
- No Blizzard model, image, or audio file is bundled with DK Mentor.

The portrait is intentionally presentation-only and does not attempt lip synchronization.

## Data refresh for the 3.1 cycle

Before building 3.1, the Death Knight dataset was re-reviewed for **Retail 12.1.0 / Midnight Season 2** on **2026-09-01**.

The review included Blizzard hotfixes, current Wowhead PvE/build/gear/consumable guidance, and current Icy Veins PvP build guidance. The audit captured the late-August Frost tuning and the August 31 Unholy hotfix when checking whether DK Mentor recommendations required changes.

See `DATA_AUDIT_v3.1.0.md` for the implementation-facing audit notes.

## Commands added

```text
/dkm prep
/dkm preset
```

## Safety boundary

DK Mentor continues to recommend and explain. It does not automatically cast abilities, choose targets, spend resources, switch talents, equip gear, apply enhancements, or execute imported preset text as code. Loadout automation remains the responsibility of the optional Loadout Pilot addon.

## Version

- DK Mentor: **3.1.0**
- Retail interface: **120100**
- Data review: **2026-09-01**
