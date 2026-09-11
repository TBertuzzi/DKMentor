# DK Mentor v3.2.0 — Testing r11

## Foco desta revisão
Refresh de guidance de 6 de setembro sobre a r10. **Valeera, atalho da configuração nativa e novo layout inicial/reset permanecem intactos.**

## Frost — validar em jogo
1. Abra **Builds -> Frost -> Mythic+** e confirme que Deathbringer continua recomendado.
2. Confirme que o texto cita **Smothering Offense** como direção de AoE e não apresenta **Frostbane** como recomendação competitiva.
3. Abra **Equipment -> Preparation**:
   - Potion of Recklessness = RECOMMENDED;
   - Light's Potential = ALTERNATIVE;
   - Dual Wield + Shattering Blade = Razorice MH + Fallen Crusader OH;
   - outros Dual Wield = Stoneskin Gargoyle MH + Fallen Crusader OH;
   - Two-Hand = Fallen Crusader.
4. Com Frostbane talentado manualmente, confirme que o tracking normal de aura/habilidade continua funcionando; o r11 muda recomendação, não remove tracking.

## Unholy / PvP
- Unholy: confirmar que Rider/San'layn e os trinkets continuam aparecendo como antes; a revisão atualizou freshness/source date, não mudou a direção principal.
- Frost PvP: Rider recomendado e Deathbringer alternativo.
- Unholy PvP: Disease recomendado e Pet alternativo.

## Regressão r10 / Valeera
- `/dkm` -> DK Codex -> Valeera.
- Testar Auto / Safe / Balanced / Fast / High Tier.
- Testar **Abrir configuração da Valeera** fora de combate.
- Confirmar bloqueio em combate.
- Resetar HUDs e confirmar Recursos -> Habilidades -> Coach -> Buffs/Debuffs sem sobreposição.
