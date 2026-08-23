# Validation Report - DK Mentor 1.0.17

- Version metadata synchronized with Retail Interface 120100.
- Settings schema bumped to 22; existing installs receive default row-width values without losing saved HUD positions or visibility choices.
- Preview HUDs is a hard override in `ShouldShowCombatBar` and the independent combat heartbeat/combat-end cleanup explicitly skip forced hiding while Preview is active.
- Blizzard-managed DK Buffs, External Buffs, and Debuffs receive explicit preview placeholders, so empty AuraContainer HUDs remain visible for positioning outside combat.
- DK Buffs, External Buffs, Debuffs, and Abilities each expose an independent 70%-160% scale and configurable icons-per-row value.
- Aura bars default to 5 icons per row and support 3-10; Abilities defaults to 11 and supports 3-11.
- AuraContainer width/flow changes are applied only out of combat; a pending-layout flag prevents protected layout mutation during combat lockdown.
- Ability and fallback aura renderers use the same saved row-width setting.
- Reset HUD positions preserves custom bar sizes; the dedicated size reset restores only bar scale/row width.
- The existing 1.0.16 native AuraContainer initialization order (`SetUnit` -> `AddAuraGroup` -> `SetEnabled`) and Cooldown Manager candidate-filter integration remain intact.
- Secret-value guards and combat-automation API blacklist remain enabled.
- `scripts/validate.py` passed.
- All addon Lua files parsed successfully with `texluac -p`.
- Final confirmation of visual layout and secure runtime behavior still requires the live World of Warcraft 12.1 client.
