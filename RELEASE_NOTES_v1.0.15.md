# DK Mentor 1.0.15

This test build rebuilds DK proc tracking around the current Midnight 12.1 Cooldown Manager recommendations for Frost, Unholy, and Blood.

The addon uses curated public Cooldown Manager IDs as read-only metadata and resolves spell/link/override data from Blizzard UI state that has already been materialized by the game. It does not import or modify the player's Cooldown Manager profile and does not automate combat.

The DK Buff bar remains active-only: useful procs and combat buffs appear when active and disappear when consumed or expired.
