# DK Mentor 2.0.4

Retail 12.1.0 maintenance release focused on the **Mind Freeze interrupt alert**.

## Fixed

The interrupt icon could fail to appear even after WoW reported the current target as interruptible. DK Mentor was still requiring `UnitCastingInfo` / `UnitChannelInfo` to expose a readable cast in the same update. Under Midnight restrictions and event ordering, that extra requirement could race the official interruptibility event and suppress the alert.

DK Mentor now treats `UNIT_SPELLCAST_INTERRUPTIBLE` and `UNIT_SPELLCAST_NOT_INTERRUPTIBLE` as authoritative target-state signals. A confirmed interruptible event keeps the Mind Freeze alert visible until the cast ends, fails, succeeds, becomes non-interruptible, or the target changes.

The two interruptibility events are also registered as target-scoped unit events, following Blizzard's own cast-bar pattern, with a fallback to normal event registration. Short deferred refreshes cover cast/combat-state propagation delays.

No spell is cast automatically and no protected action is performed.

## Preserved from 2.0.3

- Resource arc HUD remains click-through so enemies behind it can be targeted.
- Aura bars remain active-only outside HUD Preview.
- Compact DK status widget remains unchanged.
- DK Mentor remains free of loadout automation; Loadout Pilot owns that responsibility.
