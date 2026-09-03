# DK Mentor 2.0.5 live test

## Adaptive Coach basics

1. Open **Settings > Mentor intelligence...**.
2. Cycle **Essential / Mentor / Training** and confirm the Coach header reflects the selected mode.
3. Enter combat and verify the existing three-card Coach remains movable/visible according to the normal HUD settings.
4. Confirm no recommendation causes an ability to fire automatically.

## Defensive Advisor

1. Lose health gradually and confirm recovery/defensive priorities rise as health falls.
2. At critical health, verify a major defensive/recovery recommendation can become card #1.
3. On Blood, verify readable low Bone Shield stacks can surface Marrowrend.
4. Take repeated magic damage and verify Anti-Magic Shell can be favored when the combat log exposes magic-school damage.
5. Confirm hidden/secret values simply remove that signal rather than causing Lua errors.

## Interrupt / utility

1. Target an interruptible cast: Mind Freeze should appear in the dedicated interrupt icon and can also become a top Coach card.
2. Target a non-interruptible cast from a normal/elite mob: in Mentor/Training, a known/ready Asphyxiate, Blinding Sleet or Death Grip may be suggested as a possible stop.
3. Test a non-interruptible boss cast: the Coach may recommend defensive preparation, but must never claim to know a specific encounter timer.
4. Interrupt with Mind Freeze and confirm Combat Insights count the personal interrupt when the combat log reports it.
5. Let an interruptible cast complete and confirm the report can record a missed stop.

## Resource / proc coaching

1. In Frost or Unholy, approach 90%+ Runic Power and confirm Mentor/Training can warn to spend it when readable.
2. In Blood, confirm the warning waits until roughly 96%+ to avoid punishing normal Death Strike pooling.
3. Leave five or six Runes ready in Training mode and confirm the Coach can surface a Rune-use hint when readable.
4. Trigger Frost Killing Machine/Rime/Frostbane and confirm the Coach can surface Obliterate/Howling Blast/Frost Strike respectively.
5. Trigger Unholy Sudden Doom and confirm Death Coil can be surfaced.
6. Trigger supported Blood proc glows and confirm their consumer can be surfaced.
7. During readable Breath of Sindragosa, confirm Frost does not incorrectly recommend Frost Strike only because Runic Power is high.

## Unholy target state

1. On a durable target, apply Festering Wounds and confirm the combat log state can be used for wound-building/spending guidance.
2. Let Virulent Plague be removed/expire while the target remains tracked and confirm Outbreak can be suggested when that absence becomes known.
3. Change targets and confirm state follows the current target rather than leaking recommendations from the previous target.

## Combat Insights / score

1. Complete a combat lasting at least five seconds.
2. Confirm the Combat tab shows **Adaptive DK Coach — last combat** with a score and first insight.
3. Open **Details...** and verify Resources / Procs / Defensives / Interrupts are displayed as a score or N/A depending on readable data.
4. Confirm the optional post-combat popup appears, is click-through, and hides automatically.
5. Disable **Combat Insights** and/or **Post-combat popup** and verify the settings are respected.
6. Use **Clear last report** and confirm the stored report disappears.

## Regression

- Mind Freeze alert remains reliable from 2.0.4.
- Enemies remain clickable through the health/runic-power arc HUD from 2.0.3.
- Empty DK Buffs / External Buffs / Debuffs remain invisible outside HUD Preview from 2.0.2.
- Compact DK status widget and Codex source URL row remain correct from 2.0.1.
- Loadout automation does not return to DK Mentor.
- No Lua errors, taint, blocked actions, or secret-value comparison errors appear during combat.
