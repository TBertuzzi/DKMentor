# DK Mentor 2.0.9 live test checklist

1. Replace the previous DKMentor folder with the 2.0.9 test build and `/reload`.
2. Confirm `/dkm interrupt on` reports the alert as enabled.
3. Target an enemy with a clearly interruptible cast and enter combat. Verify the Mind Freeze icon appears while that cast/channel is interruptible.
4. Target a cast with the shield/non-interruptible state. Verify the Mind Freeze icon is not visibly presented.
5. While either cast is active, run `/dkm interrupt status`. In restricted combat it is valid for the API field to report `secret -> widget`; this confirms the Secret-safe presentation path is active.
6. Verify the icon disappears at cast stop/failure/success, after target changes, and when the alert is disabled.
7. Verify the interrupt indicator does not block mouse clicks on enemies during normal gameplay.
8. Unlock HUD movement outside combat and verify the interrupt icon can still be moved when visible/previewed.
9. Recheck the 2.0.8 dynamic post-combat score card and the resource arc click-through behavior for regressions.
