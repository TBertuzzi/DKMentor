# DK Mentor 3.1.5 — Voice-synced portrait and compact window

DK Mentor 3.1.5 tightens the live-test experience around the animated Lich King portrait and the main configuration window.

## Fixed
- **Portrait/audio synchronization:** `PlaySoundFile` returns a sound handle, and DK Mentor now uses `C_Sound.IsPlaying(handle)` to stop the talking animation as soon as the actual voice finishes instead of allowing the old fail-safe timeout to keep the portrait alive.
- A **0.20 s startup grace** avoids treating a newly queued voice as already finished on its first frame.
- The old busy timeout remains only as a **7-second fail-safe** for clients where a usable sound handle cannot be queried.
- Portrait hide polling was tightened from **0.25 s to 0.10 s**, so the visual disappears almost immediately after playback ends.

## More compact main window
- Main DK Mentor window reduced from **830x760** to **820x720**.
- The page area and Settings sections were compacted rather than simply scaling the whole UI down, keeping text readable.
- HUD controls, Loadout Pilot integration and all Lich King portrait controls remain available without overlapping the footer.
- DK Codex keeps its internal scrolling so the smaller window does not remove build/gear content.

## Preserved
- Arthas / Bolvar Lich King portrait selection.
- Animated talking portrait and movable/lockable portrait controls.
- Top-level draggable Layout Presets window.
- Preparation / Ready Check and enchant detection.
- SBA-friendly Build Mentor.
- Frost 2H / Dual Wield Runeforge guidance.

## Version
- DK Mentor: **3.1.5**
- Retail interface: **120100**
