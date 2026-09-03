# DK Mentor 1.1.7

## Hotfix

- Restores the **Runic Power arc** from 1.1.5.
- The 1.1.6 source logic was not the cause: its release ZIP accidentally omitted the three right-side DK Arc texture files, so WoW displayed the right StatusBar as a rectangular fallback.
- Packaging now copies the entire `Media` folder on both shell and PowerShell release paths.
- The **Health <=30% turns red** behavior from 1.1.6 is preserved.

No layout, rune, opening/zoom, opacity, movement, or Runic Power behavior was intentionally changed in this hotfix.
