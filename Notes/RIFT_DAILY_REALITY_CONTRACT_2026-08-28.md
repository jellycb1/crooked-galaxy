# Fenda Clandestina — contrato de realidades diárias

Estado: fundação implementada em 28 de agosto de 2026. Valores da segunda realidade são um primeiro envelope de balanceamento e precisam de validação física quando o perfil de nível 100 estiver disponível.

## Loop ativo

1. Nível 8 revela a Fenda e entrega permanentemente a chave da **Alfândega do Universo Morto**.
2. Cada realidade tem doze inimigos fixos, progressão própria e uma chave própria.
3. O jogador escolhe entre as realidades cujas chaves já possui; realidades futuras e os seus inimigos não são antecipados.
4. Existe uma entrada global por dia UTC. Iniciar a luta consome-a de forma atómica; fechar a aplicação, perder ou mudar de ecrã não devolve a tentativa.
5. A vitória revela então Créditos, XP e o artefacto selado, e só receber esse artefacto avança um inimigo.
6. Derrota mantém o mesmo inimigo, todo o progresso e o embalo dos mandados.

## Chaves e expansão

- Uma chave abre o conjunto inteiro e nunca é consumida.
- A realidade seguinte só pode entregar a chave quando a anterior está completa e o nível mínimo foi alcançado.
- A chave surge em caçadas normais, não dentro da própria Fenda. Isto devolve o jogador ao loop principal e evita que um sistema diário fechado se alimente sozinho.
- A segunda chave exige nível 100 e tem proteção de azar de cinco caçadas elegíveis. A aquisição seleciona a realidade nova, mas ambas continuam acessíveis por separadores.
- O save schema 22 migra o antigo `challenge_floor` para a primeira realidade, preserva progresso e inicializa os novos campos sem inventar uma chave avançada.

## Informação e surpresa

Antes da entrada são visíveis somente a realidade atual, progresso por setor, inimigo atual, poder, vida, probabilidade com a build presente e regra completa da anomalia. Não são mostrados inimigos futuros nem conteúdo do drop. A mensagem “Recompensa selada” promete equipamento e recursos superiores sem expor item, raridade, espaço, Créditos ou XP.

Após a vitória, o recibo revela o conteúdo completo e permite equipar, guardar ou reciclar. O drop é canónico por inimigo e persistido no fluxo normal de recompensa; reiniciar a aplicação não rerrola o resultado.

## Progressão e monetização

- A Fenda não consome combustível, não avança objetivos diários e não interfere com reputação, domínio ou sequência dos mandados.
- Entradas, novas tentativas, chaves, saltos, chance de vitória e revelação do drop não são vendidas.
- A pressão comercial permanece nas oportunidades adicionais do Mercado e nas recargas limitadas de combustível, ambas com custos 1/5/20 conhecidos antes da confirmação.
- Esta separação impede que o melhor desafio diário se torne pay-to-win e dá às builds um teste comparável antes de PvP assíncrono.

## Conteúdo inicial e envelope

A primeira realidade conserva os doze inimigos e seis anomalias já auditados. A segunda, **Veredito do Tempo Congelado**, reutiliza temporariamente as doze identidades localizadas através de IDs compostos próprios, acrescenta pressão vertical acima do final anterior e entrega instâncias únicas dos artefactos com +1 poder adicional. `tools/audit_rift_realities.gd` calibra os doze encontros contra as três classes e builds representativas dos níveis 100–155, em passos de cinco níveis; o envelope atual fica entre 47% e 82%, sem abertura trivial nem parede terminal impossível. Essa reutilização é uma fundação técnica; antes do lançamento, cada realidade deverá receber inimigos, textos e arte próprios.

O sistema atual prova 24 vitórias de primeira conclusão, distribuídas por no mínimo 24 dias bem-sucedidos. Não pretende sozinho preencher 365 dias: realidades adicionais, eventos rotativos, Arena e coleção permanente continuarão necessários. Uma realidade futura deve sempre trazer doze inimigos, uma chave gameplay-only, traduções completas, envelope de combate simulado e identidade visual aprovada antes de entrar no catálogo.
