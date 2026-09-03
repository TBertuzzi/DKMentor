# DK Mentor 2.0.9 - Secret-safe Mind Freeze indicator

This release fixes the persistent interrupt alert issue under Midnight's combat restrictions.

WoW can mark the target cast's `notInterruptible` boolean as a Secret Value. DK Mentor now passes that raw boolean directly to a Secret-aware frame alpha API: non-interruptible casts become transparent and interruptible casts become visible inside the WoW UI engine, without addon Lua reading the protected value.

The alert still follows cast start/stop/channel transitions, and a lightweight 120 ms cast-state heartbeat ensures restricted event payloads cannot leave it stale. It remains optional and stays click-through during normal gameplay. `/dkm interrupt status` can be used during a target cast to report which safe signal path is active.
