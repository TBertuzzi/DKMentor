# DK Mentor 1.0.19

## Hotfix: HUD lock must not hide combat bars

The **HUDs: LOCKED** setting is intended only to prevent accidental movement. In 1.0.18, Blizzard-managed aura bars could appear to vanish after locking because `UpdateManagedAuraBarChrome` made the entire host frame background/border and label transparent when the HUD was locked.

1.0.19 decouples interaction from visibility:

- LOCKED disables dragging/mouse interception only.
- DK Buffs, External Buffs, and Debuffs keep their normal visible frame chrome in combat.
- The native Blizzard `AuraContainer` remains enabled and unchanged.
- Preview HUDs still temporarily enables interaction and sample placeholders.
- Bars only in combat still controls combat visibility independently of HUD lock.

No DK proc whitelist, Cooldown Manager profile, sizing option, or AuraContainer candidate filter was changed in this hotfix.
