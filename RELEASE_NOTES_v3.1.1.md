# DK Mentor 3.1.1 — Startup Hotfix

DK Mentor **3.1.1** fixes a startup-blocking Lua compiler limit hit by the initial 3.1.0 test package.

## Fixed

- Fixed `Core.lua: main function has more than 200 local variables`.
- Reduced persistent chunk-level locals from **215 to 185**, leaving safety headroom below WoW's **200-local** limit.
- Kept all 3.1 systems intact: Preparation / Ready Check, SBA-friendly Build Mentor, layout preset export/import, and the optional movable Lich King commentary portrait.
- Added a validator guard to catch this class of failure before future packages are generated.

## Version

- DK Mentor: **3.1.1**
- Retail interface: **120100**
- Recommendation data remains reviewed for **2026-09-01**.
