# DK Mentor 1.0.10

Stability candidate for World of Warcraft Retail 12.1.0.

## Fix

PvP can mark boolean results from some Unit APIs as secret. DK Mentor now checks whether those values are accessible before comparing or branching on them. The reported `PLAYER_FLAGS_CHANGED` / `UnitIsAFK` crash is fixed, and the same protection is applied to related optional state checks.

Core automatic context, talent, and equipment switching behavior is unchanged.
