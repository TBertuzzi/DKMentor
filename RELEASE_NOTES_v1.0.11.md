# DK Mentor 1.0.11

Live-test candidate for World of Warcraft Retail 12.1.0.

## Proc visibility

The DK Buff Bar now supplements its known aura list with transient `SPELL_ACTIVATION_OVERLAY_GLOW_SHOW/HIDE` state from the Blizzard client. This lets action-button procs appear without attempting to inspect restricted enemy state or bypass aura secrecy. Blood also tracks Crimson Scourge and Hemostasis; Unholy tracks Runic Corruption.

The DK Buff Bar wraps at five icons per row and can grow to three rows when several important buffs/procs are active.

## Mind Freeze alert

A new optional movable icon-only alert appears when the current target has a cast or channel that DK Mentor can safely confirm is interruptible. The alert uses the Mind Freeze icon and displays its own cooldown state. It does not cast Mind Freeze, click buttons, select targets, or automate combat.

When Retail 12.1 marks cast details as secret, DK Mentor only uses accessible/NeverSecret fields plus the official interruptibility events; if the interruptibility cannot be confirmed, the alert stays hidden instead of guessing.
