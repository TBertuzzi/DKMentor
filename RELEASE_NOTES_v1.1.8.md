# DK Mentor 1.1.8

## Language selection

- New language control in **Settings**.
- **Automatic (WoW)** remains the default.
- Available overrides: **Português (Brasil)** and **English**.
- The choice is stored in `DKMentorDB`.
- Outside combat, selecting a language automatically reloads the UI so all DK Mentor text is rebuilt in the selected language.
- In combat, the choice is saved and applied on the next `/reload`.
- Slash command: `/dkm language auto|ptbr|en`.
