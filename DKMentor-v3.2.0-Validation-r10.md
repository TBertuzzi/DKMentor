# DK Mentor v3.2.0 — Validation r10

## Escopo
Hardening do layout inicial e do botão **Reset HUDs**.

## Alteração
Os defaults foram reorganizados em quatro bandas independentes:
- Recursos DK: `BOTTOM y=95`
- Habilidades: `BOTTOM y=175`
- Coach: `BOTTOM y=250`
- Aura bars: `BOTTOM y=395`, com X `-220 / 0 / +220`

Isso remove a sobreposição existente nos defaults anteriores, inclusive considerando o Coach no layout Large.

## Proteções
- Reset continua usando os mesmos defaults da instalação nova.
- Visibilidade dos HUDs não é alterada pelo reset de posição.
- Smoke test específico garante separação vertical e horizontal do starter layout.
