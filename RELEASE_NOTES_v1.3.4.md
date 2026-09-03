# DK Mentor 1.3.4

## Managed loadout refresh

`Save code` now does more than retain a local reference. When the selected profile already has its exact DK Mentor-managed WoW loadout (for example `DKM Raid`), DK Mentor validates the new import string and refreshes that managed loadout.

Player-created/custom-named loadouts are deliberately excluded from automatic overwrite. If WoW cannot safely apply the code, the local code remains saved and the existing loadout is not deleted.

No SavedVariables schema change.
