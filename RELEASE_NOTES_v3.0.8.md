# DK Mentor 3.0.8 - Spec-Aware Rotation Coverage & Review Font Hotfix

Version 3.0.8 focuses on two live-client issues found while testing the 3.0 branch.

## Spec-aware Assisted Combat coverage

The Combat page can inspect Blizzard Assisted Combat's rotation spell list and report which recommended abilities are present on the player's action bars. In 3.0.7, that native list could expose a stale or cross-specialization entry while the spellbook/talent state was refreshing. This caused Frost to report Unholy's Soul Reaper as a missing action-bar ability.

3.0.8 now filters Assisted Combat rotation entries through the active specialization and current known spellbook/talent state before calculating coverage. Spell overrides are still recognized, so replacement abilities remain compatible with the check.

An explicit Midnight 12.1 ownership guard also keeps Soul Reaper (spell 343294) restricted to Unholy for this coverage feature.

The result is that `Action bars: X/Y found` now represents abilities that are actually relevant to the player's current DK setup rather than every entry Blizzard may briefly expose.

## Review missing-glyph fix

The Review subtitle used Unicode arrow characters between Overview, Timeline, and Patterns. Some WoW font configurations rendered those arrows as empty square glyphs.

The subtitle now uses font-safe ASCII separators:

`Overview | Timeline | Patterns`

`Visão geral | Linha do tempo | Padrões`

The runtime validation suite also rejects the known decorative glyphs that previously caused missing-character squares.

## Unchanged

- Live Mentor / Essential / Mentor / Training logic
- Blizzard pinned Next Action card
- Review history, Timeline, and Patterns calculations
- Alert Studio and modal navigation
- DK Tools
- Midnight Secret Value safeguards
- SavedVariables schema 31
- Setup Wizard schema 301

DK Mentor remains guidance-only and never casts abilities or selects targets automatically.
