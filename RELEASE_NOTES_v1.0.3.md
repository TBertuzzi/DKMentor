# DK Mentor 1.0.3 — Release Candidate for Live Testing

DK Mentor 1.0.3 is the feature-complete candidate intended for several days of live World of Warcraft Retail 12.1 testing before the first CurseForge publication.

## 1.0 highlights

- Automatic World / Delve / Dungeon / Raid / PvP detection.
- Automatic mapped WoW talent-loadout switching.
- Automatic mapped Equipment Set switching.
- DK Buff, External Buff, Player Debuff, Ability Availability, Build, and Coach HUDs.
- Five-icons-per-row wrapping for External Buffs and Debuffs.
- Optional combat-only visibility for the aura/ability bars.
- Blizzard Assisted Combat integration and survival coaching.
- Beginner guide and source-linked build guidance.
- Optional Lich King commentary using only audio resources already installed by WoW.

## New: DK Ready Check

The Build HUD now reports whether the Death Knight is ready for the detected content. The detailed tooltip and `/dkm ready` command check:

- the mapped talent loadout for the current specialization/content;
- the mapped Equipment Set and whether it is currently equipped;
- Death Knight Runeforge coverage on each equipped weapon;
- the Unholy ghoul when Raise Dead is available.

## New: Runeforge Guard

Runeforge Guard reads the permanent enchant ID from the player's own equipped weapon item links and recognizes the current Death Knight Runeforge family. Dual-wield characters are checked on both weapons.

The guard deliberately validates **presence of a DK Runeforge**, not a universal "best rune" recommendation, because optimal rune choice can vary by build/content.

## New: Ghoul Guard

For Unholy, DK Mentor checks the player's own pet unit and flags a missing or dead ghoul. The check is suppressed during vehicle/taxi travel to reduce false alarms.

## Policy / fair-play boundary

DK Mentor remains guidance and presentation only. It does not cast abilities, automate combat actions, inspect enemy protected/secret state, or attempt to bypass Blizzard restrictions. Talent and equipment switches use Blizzard-supported player configuration APIs outside protected situations.

## 0.8.3 stability carried forward

1.0.3 includes the saved-loadout synchronization fix that keeps the native Blizzard talent selector aligned with DK Mentor's automatic loadout changes and clears the queued state against the correct saved-loadout ID.


## 1.0.3 polish

- Added AddOns-list icon metadata.
- Tightened the Build HUD layout so the info panel wastes less horizontal space.


## 1.0.3 visual polish

- Build HUD height now follows its rendered content and expands only when needed.


## 1.0.3 specialization selector

- Clicking the specialization icon in the Build HUD opens a compact Blood / Frost / Unholy selector.
- Specialization changes are always initiated by the player and are blocked during combat.
- After the specialization changes, existing automatic talent and equipment mappings continue to apply normally.
