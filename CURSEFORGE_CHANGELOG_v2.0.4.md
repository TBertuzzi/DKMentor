## DK Mentor 2.0.4

- Fixed the **Mind Freeze interrupt alert** sometimes not appearing for interruptible enemy casts in Midnight 12.1.
- Official target interruptibility events now drive the alert directly instead of depending on cast API state being readable in the same frame.
- Added target-scoped interrupt event registration and delayed cast/channel refreshes for better reliability.
- Preserves the 2.0.3 click-through resource arcs and 2.0.2 active-only aura-bar behavior.
