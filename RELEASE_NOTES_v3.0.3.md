# DK Mentor 3.0.3 — Settings & Preview UX Hotfix

DK Mentor 3.0.3 focuses on the remaining usability issues found while testing the 3.0 interface.

## Settings HUD buttons

The HUD toggle column in Settings has been cleaned up for PT-BR and English:

- labels are shorter and remain on one line;
- the left-side HUD buttons are slightly wider;
- compact labels such as **Status DK**, **Buffs DK**, **Habilidades**, **Recursos** and **Interrupção** replace long duplicated wording;
- button text uses the smaller UI font consistently;
- enabled/disabled state is still reinforced by the selected cyan button style.

The detailed explanation for every HUD remains in the description column to the right, so no information was removed.

## Faster Setup preview flow

**Test alerts** and **Preview DK Tools** no longer make the Setup Wizard feel as though it disappeared.

- preview duration is reduced from 8 seconds to **4 seconds**;
- the wizard still hides so it never covers the preview;
- a small click-through notice remains visible while previewing and explicitly says that Setup will return automatically;
- Setup returns about a quarter-second after the preview itself is restored.

The Alert Studio selected-alert preview is also shortened to the same four-second presentation window.

## Less aggressive out-of-range warning

The melee-range helper has been redesigned as a subtle hint rather than a warning banner:

- `FORA DO CORPO A CORPO` becomes **FORA DE ALCANCE** in PT-BR;
- `OUT OF MELEE` becomes **OUT OF RANGE** in English;
- smaller 136x22 footprint;
- smaller font;
- softer background/border and less aggressive text color;
- the target must remain definitely out of melee range for roughly **0.30 seconds** before the hint appears, reducing boundary flicker;
- Secret/nil/restricted range data still fails open and displays no warning.

## Setup Wizard is now directly reopenable from Settings

The Settings header now has a permanent **Setup... / Assistente...** button beside Mentor Intelligence and Language.

It reopens the same five-step Setup Wizard without deleting or resetting the player's current configuration.

The existing `/dkm setup` command remains available as well.

## Preserved behavior

- No SavedVariables migration is required; schema remains **31**.
- Setup Wizard schema remains **301**.
- Review / Timeline / Patterns are unchanged.
- Midnight Secret-safe Mind Freeze handling is unchanged.
- DK Toolkit / urgent-only Essential Mentor behavior is unchanged.
- Death and Decay tracking is unchanged.
- Loadout automation remains in Loadout Pilot.
- DK Mentor still never auto-casts, auto-targets, or performs protected combat actions.

## Compatibility

- World of Warcraft Retail
- Midnight 12.1.0
- Interface `120100`
