# DK Mentor 3.0.2 — Live test checklist

This hotfix targets a real runtime crash plus several visible UI regressions. Offline validation cannot reproduce every Retail font/UI-scale/Secret Value behavior, so verify these points in the WoW client before publishing.

## 1. Startup / upgrade

- Install 3.0.2 over 3.0.1 without deleting SavedVariables.
- `/reload` produces no Lua, taint, secret-aspect or `ADDON_ACTION_FORBIDDEN` error.
- Existing HUD positions and 3.0 settings remain intact.

## 2. Resource HUD crash regression

- Open Settings -> Preview HUDs.
- Toggle Preview ON and OFF several times.
- Open HUD appearance/layout while Preview is active.
- Test resource visibility modes Always / Fade / Combat Only.
- Confirm there is no `UpdateResourceHUD` / `NormalizeResourceVisibilityMode` nil error.
- Confirm Classic and Arcs resource styles still render.

## 3. Unsupported character regression

- Open the language picker.
- Open DK Codex -> Character Check.
- Open a Utility section that shows Known / available abilities.
- Confirm no empty-square/tofu glyph appears before selected/ready rows.
- Language selection should use cyan visual selection instead of a check-mark character.
- Character Check success rows should show readable `[OK]`.

## 4. Button visual pass

Check the main window, Settings, Combat, Codex, Review, Alert Studio and Setup Wizard.

- Action buttons use the dark/cyan DK Mentor style; old red Blizzard buttons should not remain in DK Mentor-owned panels.
- Hover/pressed states remain readable.
- Active HUD/settings toggles receive a clear cyan selected state.
- Disabled buttons remain understandable.
- PT-BR labels do not overflow their controls.

## 5. Language picker

- Automatic (WoW), Português (Brasil) and English fit cleanly.
- Selecting one language visually highlights it.
- No selection glyph is shown.
- Existing `/reload` language-application behavior remains unchanged.

## 6. Live Mentor vs DK Toolkit

With Essential mode selected and HUD Preview OFF:

- While stable and with no urgent readable cast/health condition, Live Mentor should hide instead of showing generic fallback cards.
- Trigger a clearly interruptible target cast: the interrupt alert/Live Mentor behavior still works.
- Trigger meaningful danger/low health when practical: an urgent defensive/recovery recommendation may appear.
- The full static six-row reference remains visible in the main Combat tab under **DK Toolkit**.

With HUD Preview ON:

- The Coach can still show cards for positioning.
- Its title explicitly says Live Mentor preview, so it is not confused with live Essential recommendations.

## 7. 3.0 regression pass

- Setup Wizard steps 1/2 auto-advance and steps 3/4/5 remain readable 2x2 grids.
- Alert/DK Tool previews remain unobstructed by the wizard.
- Review / Timeline / Patterns still work after several >=5s combats.
- Death and Decay tracker and melee warning still work.
- Mind Freeze Secret-safe indicator still works on interruptible casts.
- No DK Mentor feature automatically casts, targets, changes talents/spec/equipment, or Loot Spec.
