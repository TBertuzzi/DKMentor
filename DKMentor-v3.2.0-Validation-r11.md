# DK Mentor v3.2.0 — Validation r11

## Escopo
Refresh de guidance pós-hotfix sobre a r10, preservando Valeera e o hardening do layout inicial.

## Alterações de dados
- Frost Mythic+: Deathbringer permanece default; Smothering Offense passa a ser explicitamente a direção de AoE e Frostbane deixa de ser apresentado como opção competitiva recomendada.
- Frost Preparation: Potion of Recklessness recomendada; Light's Potential alternativa.
- Frost Runeforge: Razorice MH somente com Shattering Blade; Stoneskin Gargoyle MH para os demais dual-wield; Fallen Crusader OH; 2H somente Fallen Crusader no Ready Check.
- Unholy: source metadata atualizado para o guia de 2026-09-05; direção Rider/San'layn e trinkets mantida.
- Frost/Unholy PvP e stat guidance re-revisados e marcados CURRENT sem falsificar as datas originais das páginas-fonte.
- Gear metadata revisado; a restrição oficial Main Hand-only de Aman'muso continua prevalecendo no DK Mentor.

## Preservado
- Valeera / Delve Mentor r8.
- Atalho nativo da configuração da Valeera r9.
- Starter layout / Reset HUDs r10.
- Tracking de Frostbane permanece disponível para builds manuais.
- Nenhum talent import string de terceiros foi incorporado.

## Validação executada
- `python3 scripts/validate.py`: **PASS**.
- Sintaxe dos 18 módulos Lua de runtime via `texluac -p`: **PASS**.
- Smoke tests via `texlua`: **22/22 PASS**.
- Cobertura de regressão confirmada para Valeera, abertura da configuração nativa, HUD reset/starter layout e guidance r11.
- Runtime ZIP `unzip -t`: **PASS**.
- Runtime ZIP mantém exatamente um diretório raiz `DKMentor/`.
- SHA-256 do pacote de teste r11: `636e8faf26c6f14d05cd6e4e902e62e285383972105324587c23754b6dfb069b`.

## Ainda requer teste no cliente Retail
- Resolução final dos tooltips/IDs no cliente ao vivo.
- Ready Check de Runeforge com armas reais 1H/2H.
- Espaçamento final em diferentes UI Scale.
- Detecção real de Delve/Valeera e abertura do painel protegido fora de combate.

