# DK Mentor 1.1.9

- Fixed the language picker so it always opens above the main settings window and remains clickable.
- Removed automatic UI reload after selecting a language to avoid the protected `Reload()` / `ADDON_ACTION_BLOCKED` error.
- The selected language is saved immediately; type `/reload` manually to rebuild the complete DK Mentor UI in the selected language.
