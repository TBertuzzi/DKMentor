# DK Mentor 3.0.6 — live test checklist

## Pinned next action

1. Enable Blizzard Assisted Combat and target a valid enemy.
2. Open/enable the Live Mentor with **Next action: ON**.
3. Confirm card 1 is labeled **PRÓXIMA** in ptBR or **NEXT** in English.
4. Confirm card 1 tracks the same next spell Blizzard recommends/highlights.
5. Cast the recommended spell repeatedly and verify card 1 changes without jumping to another card position.
6. Confirm cards 2 and 3 can still show defensive, interrupt, utility, resource, proc, or spec-specific guidance.
7. Force an interruptible cast and verify Mind Freeze guidance still appears without replacing the fixed next-action slot.
8. Lower health / take meaningful damage and verify urgent defensive guidance still remains visually distinct.

## Fallback / toggle

9. Set **Next action: OFF** in Mentor Intelligence or Alert Studio; verify the old dynamic Mentor ordering returns.
10. Run `/dkm mentor nextaction on` and `/dkm mentor nextaction off`; verify both work.
11. Test a state where Assisted Combat has no next spell; DK Mentor must not invent an offensive recommendation.

## Regression

12. Test Essential, Mentor, and Training modes.
13. Confirm the compact dark card styling from 3.0.5 remains intact.
14. Confirm Review, Patterns, DK Tools, resource HUD, and interrupt alert still work.
15. `/reload` with no Lua, taint, Secret Value, or `ADDON_ACTION_FORBIDDEN` errors.
