# Crooked Galaxy — contrato de conteúdo do primeiro ano

Estado: fundação executável, 28 de agosto de 2026.

## Promessa mensurável

O jogador diário de referência conclui cinco caçadas por dia durante 365 dias: 1 825 contratos padrão. Com a curva de experiência atual, esse percurso termina no nível 302. O catálogo de lançamento deve, por isso, continuar a produzir descobertas até ao nível 300; nível 120 não cobre um ano completo.

Os cinco planetas atuais mantêm os níveis 1, 4, 8, 13 e 19. A partir daí, um planeta é desbloqueado a cada dez níveis: 30, 40, 50 e assim sucessivamente até 300. Isso define 33 planetas e, com quatro identidades de alvo por planeta, 132 alvos no catálogo completo de lançamento.

Estes números são um teto de produção verificável, não uma alegação de que o conteúdo já existe. O vertical slice atual contém cinco planetas e vinte alvos; faltam 28 habitats e 112 alvos para cumprir este eixo do contrato.

## Comportamento da rede de missões

- O nível desbloqueia novos planetas, mas nunca retira os anteriores.
- Cada quadro oferece três mandados com pressões segura, padrão e perigosa.
- Quando existem pelo menos três planetas, os três mandados usam destinos diferentes.
- A rotação determinística distribui exposição igualmente por todos os mundos desbloqueados e percorre todos os alvos, sem depender do equipamento do jogador.
- Planeta define habitat, família visual, ficção, viagem e possíveis famílias de saque.
- Nível do jogador define a força e a recompensa do alvo. Um alvo antigo continua relevante no nível 300.
- Uma missão aceite preserva o seu snapshot e continua em segundo plano; alterações posteriores ao quadro não a modificam.

## Limites desta promessa

Trinta e três planetas não são, por si só, 365 dias de jogo. O plano anual completo também precisa de escadas permanentes de equipamento, masmorra/desafios, coleção, objetivos e rotações especiais. Este contrato mede apenas o eixo planeta–alvo e impede que a variedade visual acabe silenciosamente a meio do ano.

O teste `test_year_one_content.gd` executa as 1 825 caçadas, confirma o nível final projetado e garante que toda a amostra atual permanece acessível. Qualquer alteração futura à experiência, frequência diária ou cadência de planetas deve atualizar simultaneamente a regra, este documento e a simulação.
