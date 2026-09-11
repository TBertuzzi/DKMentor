# DK Mentor 2.0.6 live test checklist

## Load / taint

1. Replace the previous DKMentor folder with the 2.0.6 test build.
2. Log in on a Death Knight with BugGrabber/BugSack enabled.
3. Confirm no `ADDON_ACTION_FORBIDDEN` appears while DKMentor loads.
4. `/reload` and confirm the same.

## Adaptive Coach

1. Enter combat and deliberately take damage; confirm survival coaching can react to health / recent pressure.
2. Confirm no combat-log-related Lua or forbidden-action errors occur.
3. On Blood, let Bone Shield reach low stacks or expire and confirm Marrowrend/Bone Shield guidance can appear when the player aura is readable.
4. On Frost/Unholy, verify normal proc/resource coaching still works.

## Interrupts

1. Target an enemy with an interruptible cast.
2. Confirm the Mind Freeze alert/Coach entry appears.
3. Interrupt it yourself and finish the fight; confirm the post-combat report can count the handled opportunity/personal interrupt.
4. Let another player interrupt a tracked cast and confirm it is not counted as a missed completed cast.
5. Let an interruptible cast complete and confirm the report can count it as missed.

## Existing 2.0 regressions

1. Confirm the resource arcs remain click-through during gameplay.
2. Confirm empty aura HUD backgrounds stay hidden outside Preview.
3. Confirm the compact DK status widget remains compact.
4. Confirm the Codex source URL button does not clip in ptBR.
5. Confirm Loadout Pilot remains a separate optional handoff only.
