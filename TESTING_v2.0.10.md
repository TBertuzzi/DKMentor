# DK Mentor 2.0.10 — Release Candidate live checklist

Use this checklist on Retail / Midnight 12.1 before promoting 2.0.10 to stable.

## 1. Load / upgrade safety

- [ ] Update over a working 2.0.9 install without deleting SavedVariables.
- [ ] `/reload` produces no Lua, taint, ADDON_ACTION_FORBIDDEN, or secret-aspect error.
- [ ] Existing valid HUD positions remain where expected.
- [ ] HUD movement starts **LOCKED** after login/reload.
- [ ] The one-time 2.0 notice appears only once for an account/database that has not seen it.
- [ ] A fresh install opens normally on a Death Knight.

## 2. Reset / preview polish

- [ ] Settings -> **Reset HUD positions** restores status, coach, aura, ability, resource, arc, and interrupt positions.
- [ ] Adaptive DK Coach -> **Reset Mentor settings** returns to Mentor mode and enables default coaching toggles.
- [ ] Reset Mentor settings does not erase the latest Combat Insights report.
- [ ] **Test alerts** works outside combat and shows Defensive / Proc / Resource coach cards plus Mind Freeze for ~8 seconds.
- [ ] Test alerts does not block clicking units or the world.
- [ ] Test alerts refuses to run in combat without producing errors.
- [ ] `/dkm mentor test` and `/dkm mentor reset` behave the same as the buttons.

## 3. Mind Freeze / utility

- [ ] Target an enemy with a clearly interruptible cast/channel: the Mind Freeze indicator appears.
- [ ] Target a non-interruptible cast: the Mind Freeze indicator does not falsely present as interruptible.
- [ ] The interrupt HUD remains click-through during gameplay.
- [ ] `/dkm interrupt status` works as a manual diagnostic only and prints no unsolicited debug spam.

## 4. Combat HUDs

- [ ] DK Arcs / resource HUD remains click-through in normal play.
- [ ] `Arraste para mover` appears only after HUDs are explicitly unlocked in the current session.
- [ ] Empty aura bars have no black background/title/chrome during normal play.
- [ ] Active DK buffs, external buffs, and debuffs appear and disappear correctly.
- [ ] Ability Availability Bar still updates cooldown/availability visuals.

## 5. Adaptive Coach

Test at least one meaningful combat on each available spec.

- [ ] Blood: Bone Shield / defensive / Death Strike guidance behaves plausibly.
- [ ] Frost: Killing Machine/Rime/resource guidance behaves plausibly.
- [ ] Unholy: proc / disease / wound guidance remains conservative when target aura data is restricted.
- [ ] Essential mode is quiet and urgent-only.
- [ ] Mentor mode is the balanced default.
- [ ] Training mode adds resource/proc/rune-idle coaching.
- [ ] No recommendation casts an ability automatically.

## 6. Combat Insights

- [ ] A combat lasting at least 5 seconds produces a report.
- [ ] Post-combat popup sizes itself to its actual content.
- [ ] Popup is click-through and hides automatically.
- [ ] At most three observations are shown in the popup; the full report remains in Mentor Intelligence.
- [ ] `/dkm insights` / `/dkm score` opens the latest report.

## 7. Loadout boundary

- [ ] DK Mentor does not automatically change specialization, talents, gear, or Loot Specialization.
- [ ] Codex Builds remains recommendation-only.
- [ ] Loadout Pilot handoff works when installed and fails gracefully when absent.

## Release decision

Promote 2.0.10 to stable only if sections 1-7 pass without a critical regression. Cosmetic wording/spacing issues can be deferred to 2.0.11; combat errors, taint, blocked clicks, broken interrupt presentation, or lost SavedVariables are release blockers.
