# DK Mentor v3.2.0 — Testing r10

## Foco desta revisão
Correção do layout inicial/reset dos HUDs de combate.

## Bug corrigido
Ao usar **Reset HUDs** — ou em uma instalação nova — Coach, Habilidades, Buffs DK, Buffs externos, Debuffs e Recursos podiam ficar comprimidos/sobrepostos na região inferior central da tela.

## Novo layout inicial
- **Recursos DK:** faixa inferior, centralizada.
- **Habilidades:** acima dos recursos.
- **Mentor Coach:** acima da barra de habilidades.
- **Buffs DK / Buffs externos / Debuffs:** uma única faixa acima do Coach, distribuída horizontalmente em esquerda / centro / direita.
- O reset continua preservando quais HUDs estão ligados/desligados; ele corrige somente as posições.

## Teste recomendado
1. Ative **Prévia dos HUDs**.
2. Clique **Resetar HUDs**.
3. Confirme que nenhuma barra fica sobreposta ao Coach.
4. Confirme a ordem visual: Recursos -> Habilidades -> Coach -> linha de Buffs/Debuffs.
5. Desative a prévia e faça `/reload`.
6. Volte às Configurações, ative a prévia e confirme que as posições persistiram.
7. Em uma instalação limpa/SavedVariables limpas, confirme que o primeiro layout já nasce organizado.

## Regressões para observar
- barras fora da tela em UI Scale diferente;
- Buffs DK / Externos / Debuffs sobrepostos entre si;
- Coach cobrindo Habilidades;
- Reset alterando estado ligado/desligado dos HUDs (não deve alterar).
