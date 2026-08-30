# DK Mentor 3.0.1 — Setup Wizard UX Hotfix

- Rebuilt the 3.0 Setup Wizard layout for readability.
- Coach level and Resource HUD single-choice steps now auto-advance when selected.
- Added clear current-selection feedback and persistent selected-state highlighting.
- Replaced cramped four-button rows with 2 × 2 grids for Live Mentor modules, Review/DK Tools, and final setup actions.
- Increased option-button height and constrained/wrapped long labels to prevent overlapping text.
- Removed the ambiguous `Keep current settings` footer action.
- Alert and DK Tools previews now temporarily hide the wizard so the previews are fully visible, then return to the same setup step.
- Alert Studio opened from setup now returns to the wizard when closed, and Studio previews temporarily hide the Studio so alerts remain visible.
- Final step now displays HUD lock state and supports Lock/Unlock toggling.
- Setup schema bumped to 301 so existing 3.0 users see the corrected wizard once.
- No combat-coaching, Review-scoring, or Midnight Secret Value logic changed.
