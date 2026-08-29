# Crooked Galaxy — simulação da progressão de nível

Estado: decisão implementada e reproduzível, 28 de agosto de 2026.

## Diagnóstico que motivou a alteração

A versão 0.48.0 exigia `80 + 45 × (nível − 1)` XP e a missão padrão concedia aproximadamente `36 + 7 × nível`. Como ambos cresciam linearmente, o número de caçadas por nível quase não aumentava. Consumir mais combustível convertia-se diretamente em níveis e tornava a progressão incompatível com um RPG idle de longa duração.

Na versão 0.48.0, com os seis planetas então disponíveis:

| Combustível/dia | Estratégia | Caçadas/dia | Nível no dia 365 | Dia nível 30 | Dia nível 100 | Dia nível 300 |
| ---: | --- | ---: | ---: | ---: | ---: | ---: |
| 100 | Padrão | 6,5 | 389 | 15 | 79 | 276 |
| 100 | Rota mais barata | 12,9 | 766 | 9 | 42 | 138 |
| 160 | Padrão | 10,8 | 631 | 10 | 49 | 167 |
| 160 | Rota mais barata | 20,7 | 1 200 | 6 | 26 | 85 |

## Curvas avaliadas

Foi simulado um termo quadrático apenas no XP necessário: `80 + 45 × (nível − 1) + q × (nível − 1)²`. Recompensas, combustível, ofertas e primeiros níveis permanecem iguais.

| q | 100 padrão | 100 barata | 160 padrão | 160 barata |
| ---: | ---: | ---: | ---: | ---: |
| 0,20 | 253 | 407 | 357 | 553 |
| 0,40 | 208 | 322 | 285 | 428 |
| 0,60 | 182 | 276 | 246 | 364 |
| **0,80** | **165** | **247** | **221** | **323** |
| 1,00 | 152 | 226 | 202 | 294 |

## Decisão ativa

`q = 0,80` passa a ser a regra central: `80 + 45 × (nível − 1) + arredondar(0,80 × (nível − 1)²)`. A recalibração com os trinta e quatro planetas atuais — incluindo as rotas progressivas até 128 minutos da Seguradora de Apocalipses Evitáveis, 132 minutos do Leilão de Impérios Falidos e 136 minutos da Fábrica de Coincidências Industriais — coloca o perfil de 160 combustível e rota mais barata no nível 200 ao fim do ano, antes dos desbloqueios 210–310. O jogador gratuito padrão termina no 120. Os desbloqueios iniciais continuam vivos: níveis 4/8/13/19/30 chegam aproximadamente nos dias 1/2/4/8/19; nível 50 no dia 51 e nível 100 no dia 231 para o perfil gratuito padrão. O breve destaque de um planeta recém-desbloqueado explica a diferença de dois dias relativamente à rotação sem destaque e garante que conteúdo novo aparece imediatamente no quadro.

Esta é uma estimativa conservadora: os planetas futuros terão rotas maiores e reduzirão o número de caçadas possíveis. O coeficiente é representado por `4/5` em constantes centrais e protegido por testes nos níveis 1, 2, 10 e 100. Recompensas por missão, combustível, transportes e ofertas não mudaram.
