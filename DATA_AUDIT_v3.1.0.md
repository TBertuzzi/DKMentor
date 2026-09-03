# DK Mentor 3.1.0 — Data Audit

Audit date: **2026-09-01**  
Target: **World of Warcraft Retail 12.1.0 / Midnight Season 2**

This audit is an implementation checkpoint, not a permanent claim that recommendations can never change. DK Mentor stores guide metadata separately so later Blizzard hotfixes and guide updates can be refreshed without rewriting the UI engine.

## Blizzard hotfix review

The 3.1 cycle checked the current official Blizzard hotfix notes before freezing data.

Relevant recent DK changes observed in the review included:

- **2026-08-25 Frost:** broad Frost damage tuning, including an all-ability/melee increase and an additional Obliterate increase.
- **2026-08-25 Unholy:** Unholy Devotion-related fix.
- **2026-08-31 Unholy:** fix for Dread and Virulent Plague Erupt effects interacting with several target/caster modifiers, including Foul Infections, Thrill of Blood, Incite Terror, Morbidity, Soul Reaper, Brittle, and the Rune of Apocalypse War debuff.

The audit treated these as a mandatory signal to re-check recommendations rather than blindly carrying forward 3.0.17 data.

Official source family: Blizzard World of Warcraft hotfix / patch notes.

## PvE/build/gear/preparation review

Current Wowhead Death Knight guidance was re-checked for Blood, Frost, and Unholy. The 3.1 implementation focuses on compact original summaries plus IDs; it does not copy guide prose or talent import strings.

Preparation data added/revalidated includes:

- common Midnight Season 2 DK enchants;
- ring-enchant direction by spec;
- Indecipherable Eversong Diamond and spec-specific secondary-gem direction;
- Runeforge direction, including Frost 2H/DW and Shattering Blade handling;
- flask;
- combat/healing potions;
- Thalassian Phoenix Oil;
- Void-Touched Augment Rune;
- current food/feast direction.

Headline IDs are stored in `PreparationData.lua`; item and spell display names are resolved from the WoW client whenever possible so native localization is preserved.

## PvP review

Current Icy Veins 12.1 PvP build guidance was re-checked for Frost and Unholy.

- Frost 3v3: **Rider of the Apocalypse** is represented as the current baseline recommendation; Deathbringer remains the coordinated one-shot / concentrated Pillar of Frost alternative.
- Unholy: the current source page labels the **Disease** setup as its Best 3v3 build, while other explanatory text on the same source can characterize the pet setup differently. DK Mentor therefore keeps Disease as the displayed recommended profile because that matches the source's explicit Best 3v3 heading, keeps Pet as an alternative, and avoids stronger claims than the source supports.
- Blood PvP remains a War Mode/reference entry instead of being presented as a dedicated arena-meta profile.

## SBA accessibility review

Blizzard's current Single-Button Assistant/accessibility documentation was reviewed before adding SBA-friendly guidance.

The implementation intentionally follows these boundaries:

- Blizzard owns the supported offensive sequence.
- DK Mentor does not call an automatic combat rotation or simulate SBA.
- DK Mentor only changes the **presentation/order of recommendation profiles** in its Codex.
- Defensive timing, Death Strike decisions, healing, interrupts, CC, grips, utility, positioning, movement, and situational PvP choices remain manual.

## Implementation decisions

- `Builds.lua` review date updated to **2026-09-01**.
- `GearData.lua` overall review date updated to **2026-09-01**; existing per-source guide update dates remain untouched.
- New `PreparationData.lua` is isolated from the renderer for easier future hotfix refreshes.
- Close stat/flask/gem choices are presented conservatively and should still be simulated for the individual character.
- When public guide pages disagree internally, DK Mentor records a conservative choice/alternative rather than inventing certainty.

## Release-day rule

Before publishing any future DK Mentor release that changes build, gear, or preparation data:

1. check Blizzard patch notes/hotfixes;
2. re-check current Blood/Frost/Unholy PvE recommendations;
3. re-check current PvP recommendations;
4. re-check tier, trinket, crafting, gem, enchant, Runeforge, and consumable direction;
5. update the review metadata only after that pass.
