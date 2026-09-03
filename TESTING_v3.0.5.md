# DK Mentor 3.0.5 - Live test checklist

## 1. Dark card regression

- Enable HUD Preview with Live Mentor set to Compact.
- All cards must use the dark translucent DK Mentor background; no card may become white.
- Hover a card and move the cursor away; the card must return to the dark theme.
- Switch Compact -> Medium -> Large -> Compact; no layout change may turn cards white.

## 2. Compact footprint

- With three Training cards visible, Compact must be visibly smaller than 3.0.4.
- Action, ability name and timing/reason text must remain readable in PT-BR and English.
- Header, Move hint and close button must not overlap.
- One or two live recommendations should keep dynamic width behavior.

## 3. Studio and positioning

- Alert Studio can still cycle Compact / Medium / Large.
- Scale and Opacity controls still work with all three layouts.
- Unlock HUDs, drag the Live Mentor, lock HUDs and verify the saved position remains correct.

## 4. Regression

- Setup Wizard can still be reopened.
- Preview alerts/tools still return after about 4 seconds.
- Resource HUD preview has no `NormalizeResourceVisibilityMode` error.
- Mind Freeze, Review/Timeline/Patterns, DK Tools and Loadout Pilot handoff still work.
