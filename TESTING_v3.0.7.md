# DK Mentor 3.0.7 — live test checklist

## Mentor Intelligence → Alert Studio

1. Open DK Mentor → Settings → Mentor Intelligence.
2. Click **Alert Studio**.
3. Confirm Mentor Intelligence disappears completely while Studio is open.
4. Confirm no text/buttons from the parent are visible through or over Studio.
5. Close Studio with the X and with Escape; Mentor Intelligence must return in both cases.

## Mentor Intelligence → Review

6. From Mentor Intelligence, click **Open Review**.
7. Confirm Mentor Intelligence disappears completely.
8. Switch Overview / Timeline / Patterns and confirm Review remains readable.
9. Close Review; Mentor Intelligence must return.

## Nested modal flow

10. Open Mentor Intelligence → Alert Studio → Review.
11. Confirm Studio disappears while Review is open.
12. Close Review; Studio must return.
13. Close Studio; Mentor Intelligence must return.

## Setup flow

14. Open Mentor Intelligence → Setup Wizard. Parent must hide.
15. On Setup step 5, open Alert Studio. Setup must hide.
16. Close Studio; Setup must return to step 5.
17. Finish/close Setup; the original Mentor Intelligence window must return when Setup was launched from it.

## Regression

18. `/dkm studio`, `/dkm review`, and `/dkm setup` still open normally.
19. Live Mentor NEXT card, compact dark layout, DK Tools, Mind Freeze, Review data, and Patterns still work.
20. `/reload` with no Lua, taint, Secret Value, or `ADDON_ACTION_FORBIDDEN` errors.
