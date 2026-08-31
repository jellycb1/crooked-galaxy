# Crooked Galaxy — contrato de conteúdo do primeiro ano

Estado: capacidade mecânica anual revista para a curva quadrática. Não constitui, por si só, prontidão visual ou de lançamento; esses estados pertencem a `RELEASE_READINESS_CONTRACT.md`.

## Promessa mensurável

O teto de produção conserva margem sobre o perfil mecanicamente mais rápido hoje possível: 160 unidades de combustível por dia e escolha sistemática da rota mais barata entre os três mandados. Nos trinta e cinco planetas atuais, esse perfil completa 3 263 caçadas e termina o ano no nível 200. As rotas de 124, 128, 132, 136 e 140 minutos preservam a longa espera e o valor dos transportes; os níveis 210–320 ficam além deste perfil anual. O catálogo até nível 320 constitui margem de segurança para futuras alterações de rotas, XP e economia.

Os cinco planetas iniciais mantêm os níveis 1, 4, 8, 13 e 19. A partir daí, um planeta é desbloqueado a cada dez níveis: 30, 40, 50 e assim sucessivamente até 320. Isso define 35 planetas e, com quatro identidades de alvo por planeta, 140 alvos no catálogo completo de lançamento.

O conteúdo estruturado de gameplay cobre agora os trinta e cinco planetas e 140 alvos até ao nível 320: este eixo do catálogo está mecanicamente completo. A Central de Reinícios Cósmicos fecha o pipeline com reinícios universais, backups corrompidos, quatro alvos, dois incidentes, famílias de equipamento e tradução integral. Isto não significa conteúdo de lançamento terminado: personagens, habitats, arenas e ícones ainda em fallback pertencem à dívida visual medida pelo catálogo de assets. O primeiro marco visual fechado é o slice de níveis 1–30 definido em `RELEASE_READINESS_CONTRACT.md`.

## Curva de progressão

O XP exigido usa `80 + 45 × (nível − 1) + arredondar(0,80 × (nível − 1)²)`. A recompensa dos mandados não foi reduzida. O termo quadrático mantém os primeiros desbloqueios próximos, mas impede que combustível adicional se converta quase linearmente em níveis durante todo o ano.

Cinco caçadas padrão por dia continuam a ser uma referência comparável, não o limite do jogo. Esse perfil termina o ano no nível 140. O combustível e as distâncias reais produzem resultados diferentes:

| Combustível/dia | Estratégia | Caçadas/dia | Nível no dia 365 | Dia nível 30 | Dia nível 100 | Dia nível 300 |
| ---: | --- | ---: | ---: | ---: | ---: | ---: |
| 100 | Mandado padrão | 3,9 | 120 | 19 | 231 | — |
| 100 | Rota mais barata | 6,3 | 162 | 11 | 111 | — |
| 160 | Mandado padrão | 5,5 | 148 | 12 | 139 | — |
| 160 | Rota mais barata | 8,9 | 200 | 7 | 68 | — |

Esta projeção já incorpora as rotas progressivas até 124 minutos da Oficina de Realidades Defeituosas, 128 minutos da Seguradora de Apocalipses Evitáveis, 132 minutos do Leilão de Impérios Falidos, 136 minutos da Fábrica de Coincidências Industriais e 140 minutos da Central de Reinícios Cósmicos. O nível 320 é um teto de segurança de produção, não uma promessa de que todo jogador verá cada planeta no primeiro ano.

## Comportamento da rede de missões

- O nível desbloqueia novos planetas, mas nunca retira os anteriores.
- Cruzar um nível de descoberta anuncia o novo planeta no recibo e dá prioridade à Galáxia.
- Destinos ainda não confirmados mantêm um alerta persistente no Quadro e um estado `NOVO` na Galáxia, inclusive após reiniciar.
- Cada quadro oferece três mandados com pressões segura, padrão e perigosa.
- Quando existem pelo menos três planetas, os três mandados usam destinos diferentes.
- A rotação determinística distribui exposição por todos os mundos desbloqueados e percorre todos os alvos.
- Durante os primeiros seis mandados de XP após um desbloqueio, o planeta mais recente e ainda não reconhecido ocupa exatamente um cartão e roda entre as três pressões; depois disso, ou após reconhecimento na Galáxia, regressa à rotação normal.
- Planeta define habitat, família visual, ficção, viagem e possíveis famílias de saque.
- Nível do jogador define a força e a recompensa do alvo. Um alvo antigo continua relevante em níveis elevados.
- Uma missão aceite preserva o seu snapshot e continua em segundo plano; alterações posteriores ao quadro não a modifica.

## Limites desta promessa

Trinta e cinco planetas não são, por si só, 365 dias de jogo. O plano anual completo também precisa de escadas permanentes de equipamento, Fenda/desafios, coleção, objetivos e rotações especiais. A primeira fundação de retenção semanal já existe em Operações: metas 8/20/35 e um Mandado Negro rotativo entre elites desbloqueados. Ela reutiliza conteúdo sem substituir a dívida de produção de habitats e identidades. Este contrato mede sobretudo o eixo planeta–alvo e impede que a variedade visual acabe silenciosamente para o jogador de maior intensidade.

O teste `test_year_one_content.gd` executa 1 825 caçadas de referência, confirma o nível 140 nesse perfil e protege o catálogo completo de 35 planetas/140 alvos; a auditoria padrão desbloqueia o conteúdo final de nível 320 na caçada 7 530, após 6 254,3 horas de rota-base acumulada. A auditoria `tools/audit_year_one_pacing.gd` mede tanto os perfis fixos como os quatro perfis reais de combustível. Qualquer alteração futura à experiência, reserva, custos de rota ou cadência de planetas deve atualizar simultaneamente a regra, este documento e a simulação.

## Cronologia da Fenda

A Fenda usa a mesma curva de nível, mas não combustível. Cada realidade abre por chave sequencial, oferece no máximo uma vitória por dia e permite 0–3 repetições somente após derrota. A projeção reproduzível em `tools/audit_rift_year_one_chronology.gd` usa 55% por tentativa como baseline declarado, não como promessa individual de combate.

- Gratuito padrão: nível 120 no fim do ano; conclui a primeira realidade por volta do dia 182 e alcança cinco inimigos da segunda.
- Gratuito de rota barata: nível 162; conclui as duas primeiras por volta dos dias 90/323 e alcança o primeiro inimigo da terceira.
- 160 combustível, rota barata e três repetições quando necessário: nível 200; conclui as duas primeiras por volta dos dias 55/194, alcança nove inimigos da terceira e gasta cerca de 113 Fichas em repetições nos dias de progressão.

O resultado prova que as 36 identidades atuais ultrapassam o primeiro ano até para o perfil mecanicamente mais rápido: o nível 200 só chega no dia 364, deixando ainda os checkpoints 205/210/215. A primeira projeção que indicava uma lacuna de 141 dias foi rejeitada porque ignorava o nível recomendado de cada inimigo. Uma quarta realidade não deve ser produzida antes de uma projeção de segundo ano e de builds representativas acima do nível 215.

## Entrega 0.45.0 — descoberta persistente

O schema 20 acrescentou apenas `seen_planet_ids`, separando a progressão mecânica da apresentação. Saves existentes marcaram como vistos todos os mundos já disponíveis ao seu nível, evitando falsos anúncios retroativos. A alteração atual da curva de XP não exige migração: nível e XP acumulados permanecem intactos, e o novo requisito é sempre igual ou superior ao anterior.
