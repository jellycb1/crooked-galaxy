# Crooked Galaxy — contrato de conteúdo do primeiro ano

Estado: fundação executável revista para a curva quadrática, 28 de agosto de 2026.

## Promessa mensurável

O teto de produção conserva margem sobre o perfil mecanicamente mais rápido hoje possível: 160 unidades de combustível por dia e escolha sistemática da rota mais barata entre os três mandados. Nos dezoito planetas atuais, esse perfil completa 3 421 caçadas e termina o ano no nível 205. A rota adicional de 72 minutos reduz naturalmente a velocidade relativamente ao catálogo anterior. O catálogo até nível 320 permanece como margem de segurança para futuras alterações de rotas, XP e economia.

Os cinco planetas iniciais mantêm os níveis 1, 4, 8, 13 e 19. A partir daí, um planeta é desbloqueado a cada dez níveis: 30, 40, 50 e assim sucessivamente até 320. Isso define 35 planetas e, com quatro identidades de alvo por planeta, 140 alvos no catálogo completo de lançamento.

O conteúdo de gameplay cobre agora dezoito planetas e 72 alvos até ao nível 150; faltam 17 habitats e 68 identidades para cumprir este eixo. Mercado de Memórias Usadas continua o pipeline com uma megacidade-bazar de recordações e identidades, quatro alvos, dois incidentes, famílias de equipamento e tradução integral. Os assets visuais dos onze packs mais recentes pertencem ao pipeline de entregas do utilizador e permanecem em fallback explícito.

## Curva de progressão

O XP exigido usa `80 + 45 × (nível − 1) + arredondar(0,80 × (nível − 1)²)`. A recompensa dos mandados não foi reduzida. O termo quadrático mantém os primeiros desbloqueios próximos, mas impede que combustível adicional se converta quase linearmente em níveis durante todo o ano.

Cinco caçadas padrão por dia continuam a ser uma referência comparável, não o limite do jogo. Esse perfil termina o ano no nível 140. O combustível e as distâncias reais produzem resultados diferentes:

| Combustível/dia | Estratégia | Caçadas/dia | Nível no dia 365 | Dia nível 30 | Dia nível 100 | Dia nível 300 |
| ---: | --- | ---: | ---: | ---: | ---: | ---: |
| 100 | Mandado padrão | 3,9 | 120 | 19 | 231 | — |
| 100 | Rota mais barata | 6,3 | 163 | 11 | 111 | — |
| 160 | Mandado padrão | 5,5 | 148 | 12 | 139 | — |
| 160 | Rota mais barata | 9,4 | 205 | 7 | 68 | — |

Esta projeção já incorpora as rotas de 28 minutos do Arquivo Abissal, 32 minutos de Verdântia, 36 minutos de Caldeira, 40 minutos do Condomínio Lunar, 44 minutos da Necrópole Solar, 48 minutos da Central de Tempestades, 52 minutos do Museu do Amanhã Obsoleto, 56 minutos da Biblioteca do Silêncio Taxado, 60 minutos do Resort do Horizonte de Eventos, 64 minutos do Tribunal de Clones Não Autorizados, 68 minutos do Mosteiro da Gravidade Reversa e 72 minutos do Mercado de Memórias Usadas. Futuros planetas tendem a aumentar a duração média e reduzir o número de caçadas na mesma reserva; o nível 320 continua um teto de segurança de produção, não uma promessa de que todo jogador verá cada planeta no primeiro ano.

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

O teste `test_year_one_content.gd` executa 1 825 caçadas de referência, confirma o nível 140 nesse perfil e protege o catálogo de 35 planetas/140 alvos; a auditoria padrão desbloqueia o conteúdo atual de nível 150 na caçada 2 037. A auditoria `tools/audit_year_one_pacing.gd` mede tanto os perfis fixos como os quatro perfis reais de combustível. Qualquer alteração futura à experiência, reserva, custos de rota ou cadência de planetas deve atualizar simultaneamente a regra, este documento e a simulação.

## Entrega 0.45.0 — descoberta persistente

O schema 20 acrescentou apenas `seen_planet_ids`, separando a progressão mecânica da apresentação. Saves existentes marcaram como vistos todos os mundos já disponíveis ao seu nível, evitando falsos anúncios retroativos. A alteração atual da curva de XP não exige migração: nível e XP acumulados permanecem intactos, e o novo requisito é sempre igual ou superior ao anterior.
