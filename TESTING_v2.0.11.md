# DK Mentor 2.0.11 — Localization hotfix checklist

## 1. ptBR WoW client + English DK Mentor

- [ ] Settings -> Language -> English, then `/reload`.
- [ ] Combat context buttons read **World / Delve / Dungeon / Mythic+ / Raid / PvP**.
- [ ] Compact status widget shows **World**, **Delve**, etc. instead of `Mundo`, `Imersão`, etc.
- [ ] Header content label is English and the DK Mentor specialization label is **Blood / Frost / Unholy**.
- [ ] Survival tags/descriptions and Adaptive Coach addon text are English.
- [ ] DK Codex / Guide static addon text is English.
- [ ] WoW-provided spell names may remain Portuguese; this is expected.

## 2. ptBR override

- [ ] Settings -> Language -> Português, then `/reload`.
- [ ] Context buttons and compact widget return to **Mundo / Imersão / Masmorra / Mítica+ / Raide / JxJ**.
- [ ] DK Mentor specialization labels return to **Sangue / Gélido / Profano**.
- [ ] Survival/Coach/Codex addon text is Portuguese.

## 3. Auto

- [ ] Settings -> Language -> Auto, then `/reload`.
- [ ] ptBR WoW client resolves DK Mentor to Portuguese.
- [ ] enUS/enGB client resolves DK Mentor to English.

## 4. Regression

- [ ] `/reload` produces no Lua/taint/blocked/Secret Value errors.
- [ ] Mind Freeze indicator still works.
- [ ] DK Status HUD remains compact.
- [ ] Combat Insights popup remains dynamically sized.
- [ ] HUD movement still starts locked.
- [ ] No specialization/talent/gear automation was reintroduced.
