# DK Mentor 3.0.3 — Live test checklist

This build targets Settings readability and preview/tool UX. Real Retail testing is still required for UI scale, fonts, range API behavior, and Midnight Secret Values.

## 1. Upgrade / startup

- Install 3.0.3 over 3.0.2 without deleting SavedVariables.
- `/reload` with no Lua, taint, secret-aspect, or `ADDON_ACTION_FORBIDDEN` errors.
- Existing HUD positions, Review history, Mentor settings, and Setup completion remain intact.

## 2. HUD buttons in Settings

Open Settings -> HUDs and layout.

- All left-column HUD buttons stay on a single line.
- Verify: Status DK, Coach, Buffs DK, External, Debuffs, Abilities, Resources, Interrupt.
- No label overlaps the right-side descriptions.
- Enabled toggles retain the cyan selected state.
- Toggle every row ON/OFF and confirm the label/state updates immediately.
- PT-BR and English both remain readable.

## 3. Reopen Setup

- Settings header contains **Assistente...** in PT-BR / **Setup...** in English.
- Clicking it opens the five-step wizard.
- Existing values are shown; opening Setup does not reset anything.
- `/dkm setup` still opens the same wizard.

## 4. Test alerts / tools return flow

On Setup step 5:

- Click Test alerts.
- Setup hides and previews are unobstructed.
- A small notice says Setup will return automatically in 4 seconds.
- The notice is click-through and does not obscure the main alert cards.
- Around 4 seconds later, alerts restore and Setup returns automatically.
- Repeat with Preview DK Tools.
- The wizard must never feel permanently lost or remain hidden after the preview.

## 5. Alert Studio preview

- Open Alert Studio from Setup or directly.
- Preview a selected alert.
- The preview remains visible for about 4 seconds.
- Studio returns automatically afterward.
- Closing Studio after opening it from Setup returns to Setup step 5.

## 6. Out-of-range hint

- Enable Melee Range in DK Tools.
- In combat, move definitely outside the melee range of the target.
- The new compact **FORA DE ALCANCE / OUT OF RANGE** hint appears only after a brief stable out-of-range state.
- Move back into range: it hides immediately.
- Rapidly cross the range boundary: the 0.30-second delay should reduce flashing.
- No warning is shown for nil/Secret/restricted range results.
- Preview remains movable only while HUD editing is explicitly unlocked.

## 7. Regression pass

- Preview HUDs no longer triggers the old resource visibility nil error.
- No unsupported square/check glyphs return.
- Mind Freeze interrupt presentation still works.
- Essential Live Mentor remains urgent-only during normal play.
- Review / Timeline / Patterns continue recording meaningful >=5s encounters.
- Death and Decay tracker still works.
- No DK Mentor feature automatically casts, targets, changes talents/spec/equipment, or Loot Spec.
