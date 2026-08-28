# Crooked Galaxy — simulação da progressão de nível

Estado: análise reproduzível; nenhuma curva candidata está ativa no jogo, 28 de agosto de 2026.

## Diagnóstico da versão 0.48.0

A fórmula atual exige `80 + 45 × (nível − 1)` XP e a missão padrão concede aproximadamente `36 + 7 × nível`. Como ambos crescem linearmente, o número de caçadas por nível quase não aumenta. Consumir mais combustível converte-se diretamente em níveis e torna a progressão incompatível com um RPG idle de longa duração.

Com os seis planetas atuais:

| Combustível/dia | Estratégia | Caçadas/dia | Nível no dia 365 | Dia nível 30 | Dia nível 100 | Dia nível 300 |
| ---: | --- | ---: | ---: | ---: | ---: | ---: |
| 100 | Padrão | 6,5 | 389 | 15 | 79 | 276 |
| 100 | Rota mais barata | 12,9 | 766 | 9 | 42 | 138 |
| 160 | Padrão | 10,8 | 631 | 10 | 49 | 167 |
| 160 | Rota mais barata | 20,7 | 1 200 | 6 | 26 | 85 |

## Curvas candidatas

Foi simulado um termo quadrático apenas no XP necessário: `80 + 45 × (nível − 1) + q × (nível − 1)²`. Recompensas, combustível, ofertas e primeiros níveis permanecem iguais.

| q | 100 padrão | 100 barata | 160 padrão | 160 barata |
| ---: | ---: | ---: | ---: | ---: |
| 0,20 | 253 | 407 | 357 | 553 |
| 0,40 | 208 | 322 | 285 | 428 |
| 0,60 | 182 | 276 | 246 | 364 |
| **0,80** | **165** | **247** | **221** | **323** |
| 1,00 | 152 | 226 | 202 | 294 |

## Recomendação

`q = 0,80` é o melhor ponto de partida. No pior cenário atual — 160 combustível todos os dias e escolha sistemática da rota mais barata — o nível 300 chega no dia 318 e o ano termina no 323. O jogador gratuito padrão termina no 165. Os desbloqueios iniciais continuam vivos: níveis 4/8/13/19/30 chegam aproximadamente nos dias 1/2/4/8/19; nível 50 no dia 49 e nível 100 no dia 156.

Esta é uma estimativa conservadora: os 27 planetas futuros terão rotas maiores e reduzirão o número de caçadas possíveis. Por isso, não se deve escolher um coeficiente superior antes de definir a curva de distâncias do catálogo. O próximo passo recomendado é testar `q = 0,80` em produção atrás de testes de progressão, mantendo os valores num único contrato substituível.
