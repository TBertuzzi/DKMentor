# DK Mentor 3.1.5 — Validation Report

Date: 2026-09-01

## Result
- `python3 scripts/validate.py`: **PASS** for DK Mentor 3.1.5 / Retail interface 120100.
- Runtime Lua syntax chunks checked: **13/13 PASS**.
- Static/data smoke tests: **15/15 PASS**.
- Core.lua chunk-level local count: **185**, below the validator safety limit of 190 and WoW's 200-local hard limit.

## 3.1.5 focused checks
- Voice playback stores the sound handle returned by `PlaySoundFile`.
- `C_Sound.IsPlaying(soundHandle)` is polled while the portrait is visible.
- Once the handle reports playback ended, `voiceBusyUntil` is cleared immediately instead of keeping the portrait alive for the fail-safe timeout.
- A 0.20-second startup grace protects newly queued sounds from an early false-negative.
- Portrait post-playback UI polling is 0.10 seconds.
- Main frame is 820x720, down from 830x760.
- Settings sections were compacted to remain inside the reduced page height without scaling text or removing controls.
- Arthas/Bolvar selection, DKM31 presets, Preparation, SBA-friendly guidance and Frost dual-wield Runeforge checks remain present.

## Packaging policy checks
- Retail interface remains **120100**.
- No Blizzard audio files are included; commentary still references voice resources already installed by World of Warcraft.
- CurseForge package must contain one top-level `DKMentor/` directory.

## Live-client limitation
Static validation cannot prove exact sound-driver timing or final pixel layout at every WoW UI scale. Test several short and long Preview Voice lines with Arthas and Bolvar, and inspect all three main tabs, before publishing.
