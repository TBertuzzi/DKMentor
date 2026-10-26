Release status: **promoted from the tested r2 runtime on 2026-10-26**. This checklist is retained as regression evidence for future patches.

# DK Mentor 3.3.4 - Live Validation / Regression Checklist

## 1. Addon load / patch compatibility

- Launch Retail 12.1.5 with only DK Mentor enabled first.
- Confirm no "out of date" warning for DK Mentor.
- Confirm `/dkm` opens normally and the addon reports version 3.3.4.
- Confirm no Lua error appears on login/reload.


## 2. Interrupt alert regression

With **Interrupt alert ON** and, if desired, **Action glow ON**:

- Target an enemy with a normal interruptible cast.
- Confirm the Mind Freeze HUD appears during the cast.
- Confirm the Mind Freeze action-bar glow appears when enabled.
- Let another interruptible cast start and use Mind Freeze; confirm the alert clears normally.
- Target a clearly non-interruptible cast and confirm the interrupt prompt does not falsely stay visible.
- Test at least one channeled interruptible spell as well as one normal cast.
- Run `/dkm interrupt status` during a cast if anything looks wrong and capture the chat line.

Expected: an interruptible target cast reliably produces the Mind Freeze prompt again on Retail 12.1.5.

## 3. Gear Mentor / 12.1.5 item API migration

For at least one Blood/Frost/Unholy character:

- Open Gear Mentor and verify item names render.
- Verify item icons render instead of question marks.
- Verify item-quality colors render correctly.
- Hover current gear targets and verify native item tooltips still work.
- Check Preparation/DK Ready inventory counts for item-count regressions.

Expected: no missing icon/name/color caused by removed legacy item API globals.

## 4. Valeera general presets

For Blood, Frost and Unholy, verify normal presets show:

- Combat: **Corrosive Bilespear**
- Utility: **Dundun's Favor**

Check Auto, Safe, Balanced, Fast, High Tier and Leveling.

## 5. Valeera Nemesis / Azta'rec

Verify the dedicated Nemesis preset still shows:

- Role: Healer
- Combat: Corrosive Bilespear
- Utility: Soul-Cracking Dreamcatcher
- Poison: Phantasmal Spore Toxin

Expected: Dundun's Favor must **not** overwrite the boss-specific Dreamcatcher recommendation.

## 6. Labyrinth of Kindo'jan

Enter the Labyrinth and verify:

- DK Mentor detects the content as **Delve**.
- Delve build guidance is selected in Auto mode.
- Valeera guidance is available normally.
- No special map-ID workaround/error is required.

If Auto reports World or Dungeon instead, capture the displayed context and any Lua error before changing settings.

## 7. Unholy San'layn / Blightfall

- Confirm Raid/M+/Dungeon/Delve still recommend the current San'layn/Blightfall direction from 3.3.3.
- Confirm the guide/timing text says Blightfall consumes **100% of remaining plague damage**.
- Confirm Open World still keeps Rider as the recommended direction.

## 8. HUD / protected cooldown regression

While in combat:

- Exercise Survival/Combat HUDs.
- Verify buff/cooldown visuals update normally.
- Verify Interrupt HUD updates across target changes.
- Enter/leave combat and verify cooldown visuals clear/update without protected-action errors.

## 9. Talent Tree / Assisted Combat regression

- Open Visual Talent Tree Mentor.
- Compare the active build.
- Test Saved/Create in WoW outside combat if desired.
- Toggle/open native Assisted Combat rotation behavior.

Expected: behavior remains unchanged from 3.3.3.

## 10. Gear freshness badge

- Blood, Frost and Unholy Gear sections should indicate **REVIEW** rather than pretending the pre-12.1.5 target list is fully current.
