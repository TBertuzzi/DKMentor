# DK Mentor 3.0.1 — Setup Wizard UX Hotfix

DK Mentor 3.0.1 is a focused usability and polish release for the new 3.0 Setup Wizard. No combat-coaching logic, Review scoring, Midnight Secret Value handling, DK Tools logic, or loadout responsibility boundaries were changed.

## Setup Wizard redesign

The five-step first-run wizard has been rebuilt for clarity and readability:

- Steps 1 and 2 now **advance automatically** when a single-choice option is selected.
- The currently selected Coach level and Resource HUD visibility are shown explicitly when revisiting a step.
- Selected options use a persistent highlight so the chosen state is visible.
- Steps 3 and 4 use a **2 × 2 grid** instead of forcing four long labels into one row.
- Option buttons are taller and their text is constrained/wrapped inside the button instead of overflowing into neighboring controls.
- Long Portuguese labels such as Death and Decay tracking and melee-range warnings are now readable.
- Toggle buttons show clear ON/OFF state and visually highlight enabled modules.
- The ambiguous `Keep current settings` footer button has been removed. Changes are saved immediately; Back/Next/Finish now provide the navigation.
- The final step shows the current HUD lock state and the HUD button toggles between **Unlock HUDs** and **Lock HUDs**.
- The wizard now has a standard close button and improved frame spacing.

## Preview visibility fix

Alert and DK Tools previews no longer appear behind the Setup Wizard.

When **Test alerts** or **Preview DK Tools** is used from step 5:

1. the wizard temporarily hides;
2. the preview appears in its real HUD position with no wizard covering it;
3. after the preview finishes, the wizard returns to the same step automatically.

Opening **Alert Studio** from the wizard also hides the wizard. Closing Alert Studio returns to setup step 5. The Studio's own **Preview selected alert** action now temporarily hides the Studio too, so its preview is never covered by the configuration panel.

## Upgrade behavior

The Setup Wizard schema is bumped to `301` so players who already completed the original 3.0.0 wizard receive the corrected wizard once after updating to 3.0.1. Existing combat/HUD settings are preserved.

## Preserved 3.0 systems

- Review / Timeline / Patterns and ten-encounter history.
- Confidence-aware scoring and positive feedback.
- Blood Death Strike pool awareness when readable.
- Frost Midnight Breath behavior.
- Unholy Lesser Ghoul / Dark Transformation / Putrefy coaching.
- Death and Decay tracker.
- Out-of-melee warning.
- Resource HUD Always / Fade / Combat Only modes.
- Alert Studio.
- Midnight Secret-safe Mind Freeze presentation.
- No combat-log dependency and no automatic protected actions.
