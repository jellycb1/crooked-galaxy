# Crooked Galaxy — contrato de conteúdo do primeiro ano

Estado: fundação executável, 28 de agosto de 2026.

## Promessa mensurável

O jogador diário de referência conclui cinco caçadas por dia durante 365 dias: 1 825 contratos padrão. Com a curva de experiência atual, esse percurso termina no nível 302. O catálogo de lançamento deve, por isso, continuar a produzir descobertas até ao nível 300; nível 120 não cobre um ano completo.

Os cinco planetas atuais mantêm os níveis 1, 4, 8, 13 e 19. A partir daí, um planeta é desbloqueado a cada dez níveis: 30, 40, 50 e assim sucessivamente até 300. Isso define 33 planetas e, com quatro identidades de alvo por planeta, 132 alvos no catálogo completo de lançamento.

Estes números são um teto de produção verificável, não uma alegação de que o conteúdo já existe. O catálogo implementado contém seis planetas e vinte e quatro alvos; faltam 27 habitats e 108 alvos para cumprir este eixo do contrato. Aerópolis de Penhora, desbloqueada no nível 30, é o primeiro pacote pós-vertical-slice e estabelece o formato repetível: quatro alvos, dois incidentes, famílias de equipamento, tradução integral e identidade procedural própria.

## Comportamento da rede de missões

- O nível desbloqueia novos planetas, mas nunca retira os anteriores.
- Cruzar um nível de descoberta anuncia o novo planeta no recibo da missão e dá prioridade à Galáxia em vez de repetir silenciosamente o contrato anterior.
- Destinos ainda não confirmados mantêm um alerta persistente no Quadro e um estado `NOVO` na Galáxia, inclusive após reiniciar o jogo. A confirmação é informativa: disponibilidade e força continuam exclusivamente derivadas do nível.
- Cada quadro oferece três mandados com pressões segura, padrão e perigosa.
- Quando existem pelo menos três planetas, os três mandados usam destinos diferentes.
- A rotação determinística distribui exposição igualmente por todos os mundos desbloqueados e percorre todos os alvos, sem depender do equipamento do jogador.
- Planeta define habitat, família visual, ficção, viagem e possíveis famílias de saque.
- Nível do jogador define a força e a recompensa do alvo. Um alvo antigo continua relevante no nível 300.
- Uma missão aceite preserva o seu snapshot e continua em segundo plano; alterações posteriores ao quadro não a modificam.

## Limites desta promessa

Trinta e três planetas não são, por si só, 365 dias de jogo. O plano anual completo também precisa de escadas permanentes de equipamento, masmorra/desafios, coleção, objetivos e rotações especiais. Este contrato mede apenas o eixo planeta–alvo e impede que a variedade visual acabe silenciosamente a meio do ano.

O teste `test_year_one_content.gd` executa as 1 825 caçadas, confirma o nível final projetado e garante que toda a amostra atual permanece acessível. Qualquer alteração futura à experiência, frequência diária ou cadência de planetas deve atualizar simultaneamente a regra, este documento e a simulação.

## Auditoria de intensidade de jogo

Cinco caçadas por dia são o perfil de referência, não um limite mecânico. A auditoria executável `tools/audit_year_one_pacing.gd` mede também jogadores de 10, 20 e 40 caçadas diárias. Com ofertas padrão e sem transporte, a curva atual produz:

| Caçadas/dia | Último planeta atual, nível 30 | Último planeta contratado, nível 300 | Nível após 365 dias |
| ---: | ---: | ---: | ---: |
| 5 | dia 28 | dia 363 | 302 |
| 10 | dia 14 | dia 182 | 588 |
| 20 | dia 7 | dia 91 | 1 148 |
| 40 | dia 4 | dia 46 | 1 897 |

O nível 30 exige 137 contratos; o nível 300, 1 813. Logo, o catálogo de 33 planetas cumpre um ano apenas para o perfil de cinco caçadas. Antes de produzir a maioria dos 27 planetas em falta, o produto deve decidir se o ritmo será protegido por reserva diária, retornos decrescentes, outra restrição transparente ou progressão deliberadamente aberta. A auditoria não ativa combustível nem transforma essa decisão em monetização.

## Entrega 0.45.0 — descoberta persistente

O schema 20 acrescenta apenas `seen_planet_ids`, separando a progressão mecânica da apresentação. Saves existentes marcam como vistos todos os mundos que já estavam disponíveis ao seu nível, evitando falsos anúncios retroativos; saves novos começam com Dustball Prime confirmado. A recompensa calcula qualquer banda atravessada antes de aplicar XP, o Quadro mantém o alerta até reconhecimento explícito e a Galáxia lista cada destino novo sem bloquear as três ofertas. PT/EN, migração, expansão de texto e geometria Android integram o mesmo contrato.
