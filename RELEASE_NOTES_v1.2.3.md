# DK Mentor 1.2.3

Version 1.2.3 focuses on faster specialization/profile response and parity with the compact Loadout Pilot HUD interaction.

## Faster specialization/profile response

- Automatic and manual specialization requests now prefer `C_SpecializationInfo.SetSpecialization`, while retaining the Retail ClassTalents specialization API as fallback.
- Automatic duplicate-attempt throttling is reduced from 4 seconds to 2 seconds.
- Transient specialization request/cast failures keep the intended target pending and retry after a short delay when the player is out of combat.
- The first automatic profile after `PLAYER_ENTERING_WORLD` is attempted after roughly 1 second rather than waiting for the 4-second non-essential cache refresh.
- After `PLAYER_SPECIALIZATION_CHANGED`, DK Mentor reevaluates the profile after 0.5 second instead of 1 second.

These changes do not make WoW's specialization cast itself faster. They reduce DK Mentor's own waiting/retry time around the Blizzard-supported specialization request.

## Compact Build HUD

- Right-click anywhere on the compact Build HUD to open or close DK Mentor.
- Right-clicking the specialization icon also opens/closes DK Mentor.
- Left-clicking the specialization icon still opens the manual Blood/Frost/Unholy picker.
- The existing one-line context/build/gear/DK READY presentation is unchanged.
