# DK Mentor 3.0.8 live test checklist

## 1. Frost action-bar coverage

1. Log into a Frost Death Knight.
2. Open DK Mentor -> Combat.
3. Click `Check action bars` / `Verificar barras`.
4. Confirm Soul Reaper / Ceifador de Almas is **not** listed as missing.
5. Confirm the X/Y count only reflects abilities relevant to the active Frost spellbook/talent setup.

## 2. Talent/spec refresh

1. Change a talent that adds/removes an active rotational spell if available.
2. Wait for the normal UI refresh or click `Check action bars`.
3. Confirm unlearned abilities are not counted as required.
4. Switch Frost <-> Unholy out of combat and confirm coverage refreshes for the new specialization.
5. On Unholy, Soul Reaper may be counted only when it is actually known/relevant to the active setup.

## 3. Review font safety

1. Open `Review...` or `/dkm review`.
2. Confirm the subtitle reads `Visão geral | Linha do tempo | Padrões` in PT-BR or `Overview | Timeline | Patterns` in English.
3. Confirm there are no square/missing-glyph characters in that subtitle.

## 4. Regression

- Mentor Intelligence -> Alert Studio: parent hides and returns on close.
- Mentor Intelligence -> Review: parent hides and returns on close.
- Pinned Blizzard Next Action remains card 1 when enabled.
- Compact Live Mentor cards remain dark/translucent, not white.
- Mind Freeze indicator remains functional.
- Resource HUD preview opens without Lua errors.

Live-client validation is still required for Blizzard API timing, Secret Values, and font rendering.
