# DK Mentor 1.1.0 live-client test checklist

## Upgrade

- Install 1.1.0 over 1.0.21 without deleting `DKMentorDB`.
- Confirm existing HUD positions still load.

## DK Resources style

- Open **Settings -> HUD appearance...**.
- Confirm **DK Resources** still supports the existing display mode toggle.
- Click **Style** and verify it switches between **Classic** and **DK Arcs**.
- Verify Preview works for both styles.

## DK Arcs runtime

- In **DK Arcs**, confirm:
  - Left side tracks player **Health**.
  - Right side tracks **Runic Power**.
  - Six mini-bars track **Rune recharge**.
- Test **Runes only**, **Runic Power only**, and **Runes + Runic Power**.
- Toggle **Power text** ON/OFF and confirm numeric text updates.
- Confirm **Restore DK Resources** resets style/position/scale/opacity while keeping enabled state.

## Slash commands

- `/dkm resources style arcs`
- `/dkm resources style classic`

## Regression checks

- No errors when entering/leaving combat.
- Preview still overrides combat-only visibility.
- HUD lock/unlock still affects dragging only.
