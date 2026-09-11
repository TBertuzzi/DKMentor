# DK Mentor 3.0.9 live test checklist

## 1. Existing Mind Freeze HUD regression

1. Target a mob with a clearly interruptible cast.
2. Confirm the existing Mind Freeze HUD behaves exactly as in 3.0.8.
3. Confirm non-interruptible casts do not become actionable just because the new glow exists.
4. Run `/dkm interrupt status` during a cast if needed.

## 2. Direct action-bar glow

1. Put Mind Freeze directly on a Blizzard action bar.
2. Keep `Action glow` enabled.
3. Start an interruptible enemy cast while Mind Freeze is ready.
4. Confirm only the Mind Freeze action button receives the small cyan pulse/border.
5. Interrupt or let the cast end and confirm the glow disappears promptly.
6. Put Mind Freeze on real cooldown and confirm the glow is suppressed while it is unavailable.

## 3. Macro action-bar glow

1. Create/place a simple macro whose current spell is Mind Freeze, for example a focus/target Mind Freeze macro.
2. Reload or change the action-bar slot out of combat so the target cache refreshes.
3. Trigger an interruptible cast.
4. Confirm the macro button receives the glow.
5. Confirm normal Blizzard proc highlights on unrelated buttons are not removed or overwritten.

## 4. Toggle behavior

1. `/dkm interrupt glow off` -> existing interrupt HUD still works, action-bar glow does not.
2. `/dkm interrupt glow on` -> action-bar glow returns on the next valid opportunity.
3. Open Settings -> `Interrupt options...` and confirm Alert Studio opens directly on Interrupt.
4. Toggle `Action glow` there and confirm the setting persists through `/reload`.

## 5. Interrupt sound

1. Confirm Sound is OFF by default for a fresh/default Interrupt Studio configuration.
2. Enable it with `/dkm interrupt sound on` or Alert Studio -> Interrupt -> Sound.
3. Trigger one interruptible cast and confirm one short Blizzard sound plays.
4. Let the cast continue for more than one second and confirm the 120 ms refresh loop does not repeat the sound.
5. Trigger a second new cast and confirm the sound can play again.
6. `/dkm interrupt sound off` -> no interrupt sound while the visual HUD/glow continue to work.

## 6. Action bar / state changes

- Move Mind Freeze to another action slot out of combat and confirm the new button glows after refresh.
- Change specialization/talents out of combat and confirm no Lua error occurs.
- Enter/leave combat and confirm stale glow frames are cleaned up.
- Test HUD Preview / Alert Studio interrupt preview and confirm the action glow preview cleans itself up.

## 7. 3.0 regressions

- Frost Action Bar coverage still does not request Soul Reaper/Ceifador de Almas.
- Review subtitle has no missing-glyph squares.
- Alert Studio / Review modal navigation remains clean.
- Compact Live Mentor cards remain dark/translucent.
- Resource HUD preview opens without Lua errors.

Live-client validation is required for action-button visibility, macro resolution, cooldown state, and Secret Value behavior during real combat.
