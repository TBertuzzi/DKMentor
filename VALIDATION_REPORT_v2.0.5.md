# DK Mentor 2.0.5 validation report

Validated against the Retail 12.1.0 addon target (`Interface: 120100`).

## Automated checks

- `python3 scripts/validate.py` — PASS
- `texluac -p Core.lua` — PASS
- `texluac -p MentorEngine.lua` — PASS
- `texluac -p Data.lua` — PASS
- `texluac -p Localization.lua` — PASS
- `texlua tests/codex_smoke.lua` — PASS
- `texlua tests/mentor_engine_smoke.lua` — PASS

## 2.0.5 feature guards

- Adaptive Coach modes: Essential / Mentor / Training.
- Existing `/dkm coach health on|off` preference remains honored for health-adaptive defensive recommendations.
- Defensive Advisor uses only readable health/combat-log data.
- Interrupt state uses target-scoped interruptibility events plus delayed cast-API refreshes to tolerate Midnight event ordering.
- Non-interruptible non-boss casts can surface a ready DK control response without claiming the target is controllable.
- Resource sampling skips inaccessible values and uses a Blood-specific near-cap threshold.
- Frost Breath state suppresses the generic near-cap Frost Strike recommendation when that aura is readable.
- Proc analytics cover Blood Crimson Scourge / Boiling Point / Vampiric Strike, Frost Killing Machine / Rime / Frostbane, and Unholy Sudden Doom.
- Blood Bone Shield and Unholy Festering Wound / Virulent Plague state are consumed only when readable or derived from readable combat-log events.
- Combat Insights and DK Mentor Score use only dimensions for which readable combat samples were collected.
- Combat Insights panel hides when the feature is disabled; the post-combat popup is click-through and is hidden when its toggle is disabled.
- World/Delve elite emphasis is reactive only; DK Mentor does not implement encounter-timer automation.

## Safety / regression guards

- SavedVariables schema remains `29`.
- No loadout/spec/talent/equipment automation was reintroduced.
- No ability or targeting execution APIs are used by `MentorEngine.lua`.
- 2.0.4 Mind Freeze event-authority and delayed-refresh guards remain in `Core.lua`.
- 2.0.3 resource-arc parent remains permanently mouse-disabled so world units stay clickable through the HUD.
- 2.0.2 empty aura containers remain visually absent outside HUD Preview.
- 2.0.1 compact DK status widget and Codex source-URL layout remain guarded.
- Packaging scripts include `MentorEngine.lua` and the complete `Media` folder.

## Live-game checks still recommended

Static validation cannot reproduce every secret-value transition or encounter-specific cast/control immunity in the live client. Before public release, use `TESTING_v2.0.5.md` for a short live pass on Blood, Frost, and Unholy, especially interrupt/control suggestions, proc-glow consumption, Blood Bone Shield, Unholy wound/disease state, and post-combat score generation.
