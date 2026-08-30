# Crooked Galaxy — contrato das Agências de Caçadores

Estado: direção de produto aprovada, fundação de regras implementada e criação inicial/diretório/membership/candidatura real provados no backend local. Não existem ainda aprovação de candidaturas, convite, saída, gestão de roster/cargos, UI social ou recompensa online; o cliente normal não deve fingir o contrário.

O protocolo partilhado de versão da API, UTC do servidor, snapshots de personagem, comandos idempotentes e recibos está definido em `BACKEND_VERTICAL_SLICE_CONTRACT.md`. Os registos de Agência podem especializar esse envelope, mas nunca contorná-lo.

## Identidade

O equivalente temático de uma guild chama-se **Agência de Caçadores** em português e **Bounty Agency** em inglês. Uma Agência reúne caçadores independentes para localizar e capturar procurados grandes demais para uma investigação individual.

Vocabulário canónico:

- membro: **Agente / Agent**;
- líder: **Diretor / Director**;
- oficial: **Coordenador / Coordinator**;
- atividade: **Mandado de Agência / Agency Warrant**;
- chefe coletivo: **Procurado Galáctico / Galactic Most Wanted**;
- progressão: **Prestígio da Agência / Agency Prestige**;
- guild hall: **Sede da Agência / Agency Headquarters**.

Uma futura união entre Agências chama-se **Consórcio / Consortium**. Consórcios não fazem parte do lançamento inicial e não devem ser implementados antes de existir população real suficiente.

## Autoridade e pertença

- Agências existem apenas no backend autoritativo do shard `International 1`.
- Um personagem pode pertencer a no máximo uma Agência no mesmo shard.
- Membership nunca é guardado como verdade dentro do save local do jogador.
- O roster máximo inicial é de 25 personagens e possui exatamente um Diretor.
- Cargos iniciais: Diretor, Coordenador, Agente e Recruta.
- Diretor gere perfil, candidaturas, membros, cargos e Mandados.
- Coordenadores gerem perfil, candidaturas, membros e Mandados, mas não nomeiam outro Diretor.
- Entrada pode ser aberta, por candidatura ou convite.
- O roster semanal elegível é fotografado pelo servidor. Apenas membros com atividade normal recente entram nas metas; inativos permanecem na Agência sem tornar o Mandado impossível. Entradas tardias não podem reivindicar retroativamente uma recompensa já produzida.

Toda mutação social usa revisão esperada e event ID idempotente. O servidor rejeita duplicados, revisões concorrentes, personagens estrangeiros e operações de outro shard. O cliente envia intenção; nunca envia saldo, Prestígio, progresso total ou cargo como autoridade.

## Desbloqueio

O acesso de produto abre no nível 8, depois de o jogador conhecer mandados, equipamento e progressão básica. O backend pode exigir também onboarding completo, nome aprovado e sessão autenticada.

O APK local atual mantém `agency_backend = false`. Não deve mostrar roster inventado, bots apresentados como jogadores, chat falso ou estado “online”.

O limite `RemoteAgencyDispatcher` existe apenas como infraestrutura online isolada. Ele exige ownership autenticado, mantém revisão social separada da economia, aceita uma única intenção por vez, repete resultados incertos apenas com a identidade original e apaga toda a apresentação social ao fechar. Não é autoload, não entra em `GameState` e não possui cache offline. Os RPCs locais já leem membership, listam páginas de Diretório, criam uma Agência inicial com o criador como Diretor e submetem uma candidatura exata; aprovação, convite, saída e gestão continuam ausentes.

O Diretório expõe páginas de no máximo 25 resumos, sem nomes ou IDs de membros: identidade e nome da Agência, revisão social, contagem, modo de recrutamento, locale preferido e capacidade calculada. Cursores e IDs duplicados falham fechados. A criação envia apenas nome sem espaços exteriores, modo `open`/`application`/`invite` e locale `pt`/`en`/`multi`; Nakama gera o ID, cria o grupo com limite 25 e liga o criador como único Diretor. O marcador idempotente fica também nos metadados do grupo para uma repetição recuperar uma criação mesmo se o recibo separado falhar. Roster, cargo, Prestígio e saldo nunca são aceites do cliente.

`agency_apply` aceita apenas o ID de uma Agência e revisão social zero de um personagem sem membership. O servidor rejeita Agência inexistente, cheia, apenas por convite, membership ou candidatura prévia. Entrada `open` torna o personagem Agente imediatamente; modo `application` cria uma candidatura roster-free. Um recibo server-only é preparado antes da aresta Nakama e finalizado depois dela, permitindo que uma repetição exata recupere uma interrupção sem criar outra candidatura. Nenhum cargo, nome de membro ou decisão de aprovação vem do candidato.

## Mandado de Agência semanal

Cada semana UTC produz um Mandado com roster e metas estáveis quando existem pelo menos quatro Agentes elegíveis. Agências menores continuam válidas, mas precisam recrutar antes de abrir uma operação coletiva. A atividade possui três fases.

### 1. Investigação

Caçadas normais concluídas pelos Agentes geram uma unidade de Informação. Apenas as primeiras três contribuições de cada Agente por dia UTC contam.

O limite é independente de combustível comprado: recarregar permite jogar mais, mas nunca ultrapassa três Informações coletivas no dia. Fenda, Arena, combate repetido, claims e compras não contam.

A meta inicial é `máximo(18, membros elegíveis × 6)`. Isso pede aproximadamente dois dias ativos por Agente sem exigir participação perfeita dos 25.

### 2. Localização

Ao completar Informação, o servidor revela o Procurado Galáctico e abre a captura. Antes disso, a UI deve mostrar pistas e silhueta, não drops ou estatísticas finais.

### 3. Captura coletiva

Cada Agente elegível recebe uma tentativa gratuita por dia UTC, sem combustível e sem repetição premium. O inimigo é instanciado no checkpoint do próprio Agente, entre os níveis 8 e 320.

Contribuição usa resultado normalizado, nunca dano bruto:

- derrota legítima: 3 pontos;
- vitória: 10–15 pontos conforme desempenho relativo contra a instância adequada;
- meta inicial: `máximo(60, membros elegíveis × 30)`.

Assim, um Agente de nível 20 pode contribuir ao lado de um Agente de nível 200 sem o segundo transformar dano absoluto em domínio automático do ranking.

## Elegibilidade e recompensas

Uma Agência só conclui o Mandado ao atingir a meta coletiva de captura. Um personagem recebe recompensa apenas se estava no roster semanal e realizou pelo menos uma destas ações:

- três contribuições válidas de Informação; ou
- uma tentativa válida de captura.

Recompensas iniciais permitidas: Créditos, Sucata, Prestígio, troféus e apresentação da Sede. Não conceder equipamento exclusivo superior, Warp Chips escaláveis por gasto, combustível adicional, níveis, atributos ou probabilidades de combate.

Valores finais de Créditos/Sucata dependem de simulação com economia de servidor e não estão definidos pela fundação local.

## Integridade comercial

- Warp Chips não compram Informação, dano, tentativas, ranking, membership nem recompensa.
- Recargas de combustível não contornam o limite diário de Informação.
- Não existe repetição paga do Procurado Galáctico.
- Doações premium não aumentam poder ou Prestígio competitivo.
- O ranking não usa gasto, dano bruto ou saldo do jogador.
- Nenhuma recompensa coletiva torna Agência obrigatória para competir no RPG individual.

## Ranking e maturidade

O primeiro ranking pode usar Mandados concluídos, Prestígio conquistado e participação distribuída. Tempo de conclusão serve apenas como desempate. Agências devem competir em faixas de maturidade para organizações antigas não bloquearem permanentemente novas.

Chat, denúncias, bloqueios, moderação de nomes, histórico administrativo e auditoria são requisitos prévios a comunicação livre. Sem essa infraestrutura, a primeira versão pode funcionar com mensagens predefinidas e registo de atividade.

## Ordem de implementação

1. conta autenticada, relógio e personagem autoritativos;
2. endpoint de Agência, roster, cargos, candidatura e revisões — criação, Diretório, membership e submissão de candidatura provados; aprovação, convite, saída e gestão ainda pendentes;
3. Mandado semanal e eventos idempotentes;
4. recompensas e Prestígio transacionais;
5. UI de Agência e Sede;
6. ranking por faixa;
7. comunicação moderada;
8. Procurados adicionais e, apenas mais tarde, Consórcios.

Arena, ranking global, Agências e Consórcios devem reutilizar a mesma identidade remota. Nenhum deles pode assentar na autoridade atual do dispositivo.
