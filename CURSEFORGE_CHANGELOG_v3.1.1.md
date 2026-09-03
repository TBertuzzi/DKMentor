# DK Mentor 3.1.1

### Hotfix
- Fixed a startup-blocking Lua compiler error: `Core.lua: main function has more than 200 local variables`.
- Refactored persistent Core state/helpers to stay safely below WoW's local-variable limit.
- Added a build-time regression guard for the limit.
- No 3.1 feature was removed: Preparation / Ready Check, SBA-friendly guidance, layout presets and the optional Lich King portrait remain included.
