# DK Mentor 3.0.0 — Live Mentor, Review & DK Tools

Major release: DK Mentor now completes the learning loop from live combat guidance to post-combat review and recurring pattern analysis.

## New
- **Review 3.0** with Overview, Timeline, Patterns, confidence-aware findings, positive feedback, and history for the latest 10 meaningful encounters.
- **Blood Death Strike pool awareness** using readable Coagulating Blood state; Review can show average/max readable pool at Death Strike casts without inventing restricted values.
- **Midnight Unholy coaching** updated around Lesser Ghouls, Dark Transformation, Putrefy, Festering Strike, and Scourge Strike.
- **Frost Breath update** removes the obsolete assumption that Breath continuously drains Runic Power.
- **DK Tools:** Death and Decay duration/charge tracker and Secret-safe out-of-melee warning.
- **Resource visibility modes:** Always / Fade out of combat / Combat Only.
- **Alert Studio** with category preview, scale, opacity, per-category pulse, and optional built-in Blizzard sounds.
- **3.0 Setup Wizard** for Coach level, HUD visibility, modules, Review/DK Tools, and positioning.
- New commands: `/dkm review`, `/dkm patterns`, `/dkm studio`, `/dkm setup`, `/dkm tools`, and `/dkm resources visibility ...`.

## Safety / compatibility
- Preserves Midnight Secret-safe Mind Freeze behavior.
- No CLEU dependency and no automatic combat actions.
- Resource arcs remain click-through; movement controls remain edit-only.
- Restricted/secret values fail safely instead of being guessed.
- Loadout automation remains the responsibility of Loadout Pilot.

SavedVariables schema: **31**. Retail interface: **120100**.
