# DK Mentor 1.0.15 live test checklist

Focus: Midnight 12.1 / Season 2 proc and Cooldown Manager parity.

## Frost
- On training dummies, verify Killing Machine and Rime appear only while active and disappear when consumed.
- Verify Freezing Tempest stacks from the Season 2 set are visible while active.
- If talented, verify Frostbane, Killing Streak, Bonegrinder, Icy Talons and Chosen of Frostbrood states appear when Blizzard exposes them.
- Verify Pillar of Frost / Breath windows and important cooldowns update normally.

## Unholy
- Verify Sudden Doom appears and disappears with Death Coil/Epidemic consumption.
- Verify Lesser Ghoul stacks, Runic Corruption and Forbidden Knowledge are shown while active.
- If San'layn is used, verify Essence of the Blood Queen / Visceral Strength / Vampiric Strike states.
- Verify current Midnight Dark Transformation and Army/Putrefy/Soul Reaper cooldowns.

## Blood
- Verify Bone Shield, Hemostasis and Crimson Scourge are shown only while active.
- If talented, verify Boiling Point and San'layn Essence/Visceral Strength/Vampiric Strike states.
- Verify Dancing Rune Weapon, Vampiric Blood and Reaper's Mark cooldown tracking.

## Cooldown Manager parity
- Compare DK Buffs against Blizzard Tracked Buffs/Tracked Bars during combat.
- In normal play no inactive placeholder should occupy DK Buffs.
- In HUD Preview only, sample icons may appear for positioning.
- With "bars only in combat" enabled, all combat bars must hide immediately on combat end.

## Safety
- Test PvP for secret-value errors.
- Confirm no ADDON_ACTION_FORBIDDEN / taint errors.
- Confirm DK Mentor never changes the player's Blizzard Cooldown Manager layout.
