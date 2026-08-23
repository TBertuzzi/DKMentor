# DK Mentor 1.0.14

Stability fix for combat-only HUD visibility. DK buff, external buff, debuff, ability and interrupt HUDs now honor the definitive combat-end event immediately. Transient proc fallbacks are also cleared when combat ends so stale procs cannot remain visible.
