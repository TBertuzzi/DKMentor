# DK Mentor 2.0.5 — Adaptive DK Coach

This is the feature-complete DK Mentor 2.0 combat-coaching pass. The addon remains guidance-only and never presses an ability, changes a target, or bypasses Blizzard combat restrictions.

## Adaptive DK Coach

The existing three-card Coach is now driven by a live priority layer instead of health percentage alone. It can prioritize, when the client exposes the required state:

- emergency survival and recovery;
- Mind Freeze on an interruptible target cast;
- Asphyxiate / Blinding Sleet / Death Grip as possible stops for non-interruptible non-boss casts;
- defensive preparation during observable non-interruptible boss casts;
- Runic Power near-cap warnings;
- high-value proc reactions;
- excessive idle Runes in Training mode;
- earlier defensive preparation against elites in World/Delve content;
- Blood Bone Shield refresh guidance when stack count is readable;
- Unholy disease/Festering Wound guidance derived from readable combat-log state;
- Frost Killing Machine/Rime/Frostbane proc consumption guidance.

The original curated context recommendations remain the fallback layer, so the Coach is still useful whenever combat values are hidden by Midnight.

## Coaching intensity

Three modes are available from **Settings > Mentor intelligence...** or `/dkm mentor`:

- **Essential** — urgent survival and interrupt calls only.
- **Mentor** — balanced default with defensive, utility, resource and proc priorities.
- **Training** — adds rune-idle and deeper execution coaching.

Individual toggles are available for Defensive Advisor, Interrupt/Utility, resource warnings, proc warnings, Solo/Delve emphasis, Combat Insights, and the post-combat popup.

## Defensive Advisor

DK Mentor now combines readable health state with a five-second recent-damage window. It distinguishes repeated magic pressure when the combat log exposes school information and can favor Anti-Magic Shell over a generic physical defensive response.

Blood receives spec-aware handling for Vampiric Blood, Death Strike, Rune Tap and Bone Shield. Frost/Unholy receive Icebound Fortitude, Death Strike and Anti-Magic Shell priorities without replacing the player's own encounter planning.

## Interrupt & Utility Coach

The 2.0.4 Mind Freeze reliability work is now integrated into the Coach. Interruptible casts can become the top recommendation. A non-interruptible cast on a non-boss target can surface a ready DK stop such as Asphyxiate, Blinding Sleet or Death Grip.

Boss casts are intentionally generic: DK Mentor reacts to an observable non-interruptible cast but does not pretend to know DBM/BigWigs encounter timers or hidden mechanic intent.

## Resource / proc waste detection

During combat, readable resource state is sampled without branching on secret values. DK Mentor can detect prolonged near-cap Runic Power and five-or-more ready Runes. Blood uses a more conservative Runic Power threshold because intentional Death Strike pooling is part of the spec.

Curated proc rules estimate whether important proc windows were consumed. Initial coverage includes Blood Crimson Scourge/Boiling Point/Vampiric Strike, Frost Killing Machine/Rime/Frostbane, and Unholy Sudden Doom. Frost near-cap warnings are suppressed while a readable Breath of Sindragosa state is active.

## Combat Insights and DK Mentor Score

Combats lasting at least five seconds can generate a local post-combat report with:

- overall DK Mentor Score;
- resource execution;
- proc consumption;
- interrupt handling;
- critical-health defensive response;
- minimum health;
- Runic Power near-cap time;
- Rune-idle time;
- detected proc expirations;
- personal interrupts and resolved interrupt opportunities;
- concise improvement notes.

Only dimensions backed by readable combat data contribute to the score. The report is shown in a new **Adaptive DK Coach — last combat** panel on the Combat tab and can optionally appear as a short click-through post-combat popup.

## Safety / scope

- No ability automation.
- No targeting automation.
- No loadout automation; Loadout Pilot retains that responsibility.
- No encounter-timer replacement for DBM/BigWigs.
- No attempt to inspect or compare inaccessible secret values.
- SavedVariables schema remains 29.
