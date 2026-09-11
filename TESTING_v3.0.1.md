# DK Mentor 3.0.1 — Setup Wizard live test checklist

This release changes the first-run/setup UX. Live WoW testing is still required because offline validation cannot reproduce every frame-scale, font, and Midnight runtime behavior.

## 1. Upgrade / startup

- Install 3.0.1 over a 3.0.0 profile without deleting SavedVariables.
- `/reload` with no Lua, taint, secret-aspect, or `ADDON_ACTION_FORBIDDEN` errors.
- The corrected Setup Wizard opens once because setup schema changed to 301.
- Existing HUD positions and combat settings remain intact.

## 2. Step 1 — Coach level

- Buttons are readable and do not overlap.
- Current Coach selection is shown above the options.
- Click Essential, Mentor, or Training: the choice applies and the wizard advances immediately to step 2.
- Go Back: the selected Coach option is visibly highlighted.

## 3. Step 2 — Resource HUD

- Always / Fade out of combat / Combat Only fit inside their buttons.
- Current visibility mode is displayed.
- Clicking an option applies it and automatically advances to step 3.
- Going Back shows the selected option highlighted.

## 4. Step 3 — Live Mentor modules

- Defensive / Utility / Resources / Procs appear as a clean 2 × 2 grid.
- No text overlaps another button.
- ON/OFF states are readable.
- Enabled modules are visibly highlighted.
- Toggling one option keeps the wizard on step 3.
- Next proceeds to step 4.

## 5. Step 4 — Review and DK Tools

- Review / Post-combat popup / D&D tracker / Melee range appear in a 2 × 2 grid.
- Portuguese labels fit/wrap inside their own buttons.
- No text overlaps another control.
- ON/OFF and highlight states update immediately.

## 6. Step 5 — Preview and HUD positioning

- Four actions appear in a readable 2 × 2 grid.
- HUD movement state shows LOCKED/UNLOCKED (or translated equivalent).
- Unlock HUDs changes to Lock HUDs after use and vice versa.
- Test alerts hides the wizard, shows the complete alert preview unobstructed, then returns to step 5 after the preview ends.
- Preview DK Tools hides the wizard, shows DnD/melee preview unobstructed, then returns to step 5.
- Alert Studio opens without the wizard behind/over it; its own selected-alert preview hides Studio while the preview runs; closing Studio returns to step 5.
- Finish closes setup and stores completion.

## 7. Regression checks

- Mind Freeze alert still works on an interruptible target cast.
- Resource arcs remain click-through.
- HUD drag handles only appear when explicitly unlocked.
- Empty aura containers remain hidden outside Preview.
- `/dkm review`, Timeline, and Patterns still work after meaningful combats.
